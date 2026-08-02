import MetalKit
import OSLog
import QuartzCore
import UIKit

struct FireUniforms {
    var resolution: SIMD2<Float>
    var time: Float
    var heat: Float
    var deltaTime: Float
    var quality: Float
    var burst: Float
    var flameTint: SIMD4<Float>
}

struct SparkVertex {
    var position: SIMD2<Float>
    var life: Float
    var seed: Float
}

private struct SparkParticle {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var age: Float
    var lifetime: Float
    var seed: Float
}

final class FireRenderer: NSObject, MTKViewDelegate {
    var heat: Float = Float(GameConstants.initialHeat)
    var isActive = true
    var flameTint = SIMD4<Float>(1, 0.48, 0.12, 1)

    private let logger = Logger(subsystem: "com.example.Takibi", category: "FireRenderer")
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let flamePipeline: MTLRenderPipelineState
    private let sparkPipeline: MTLRenderPipelineState
    private var drawableSize = SIMD2<Float>(1, 1)
    private var startTime = CACurrentMediaTime()
    private var lastFrameTime = CACurrentMediaTime()
    private var displayedHeat: Float
    private var particles: [SparkParticle] = []
    private var spawnAccumulator: Float = 0
    private var qualityScale: Float = 1
    private var sampledFrameTime: Double = 0
    private var sampledFrames = 0
    private var metricsElapsed: Double = 0
    private var burstEnergy: Float = 0

    init(view: MTKView) {
        guard
            let device = view.device,
            let commandQueue = device.makeCommandQueue(),
            let library = device.makeDefaultLibrary(),
            let fireVertex = library.makeFunction(name: "fireVertex"),
            let fireFragment = library.makeFunction(name: "fireFragment"),
            let sparkVertex = library.makeFunction(name: "sparkVertex"),
            let sparkFragment = library.makeFunction(name: "sparkFragment")
        else {
            fatalError("Metal device, queue, or shader functions are unavailable")
        }

        self.device = device
        self.commandQueue = commandQueue
        self.displayedHeat = Float(GameConstants.initialHeat)

        do {
            flamePipeline = try Self.makePipeline(
                device: device,
                view: view,
                vertex: fireVertex,
                fragment: fireFragment
            )
            sparkPipeline = try Self.makePipeline(
                device: device,
                view: view,
                vertex: sparkVertex,
                fragment: sparkFragment
            )
        } catch {
            fatalError("Unable to create Metal pipelines: \(error)")
        }

        super.init()
        UIDevice.current.isBatteryMonitoringEnabled = true
        logger.info("Fire renderer started on \(device.name, privacy: .public)")
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        drawableSize = SIMD2(Float(max(size.width, 1)), Float(max(size.height, 1)))
    }

    func draw(in view: MTKView) {
        guard isActive, let drawable = view.currentDrawable, let descriptor = view.currentRenderPassDescriptor else {
            return
        }

        let now = CACurrentMediaTime()
        let delta = min(max(now - lastFrameTime, 1.0 / 240.0), 0.1)
        lastFrameTime = now
        // A real fire swells over several seconds instead of instantly scaling.
        displayedHeat += (heat - displayedHeat) * min(1, Float(delta) * 1.05)
        burstEnergy = max(0, burstEnergy - Float(delta) * 1.55)

        updateParticles(deltaTime: Float(delta), heat: displayedHeat)

        var uniforms = FireUniforms(
            resolution: drawableSize,
            time: Float(now - startTime),
            heat: min(max(displayedHeat, 0), 100),
            deltaTime: Float(delta),
            quality: qualityScale,
            burst: burstEnergy,
            flameTint: flameTint
        )

        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        encoder.label = "Takibi fire and sparks"
        encoder.setRenderPipelineState(flamePipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<FireUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        drawSparks(encoder: encoder, uniforms: &uniforms)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()

        recordPerformance(frameTime: delta, view: view)
    }

    func triggerWoodBurst() {
        burstEnergy = 1
        for _ in 0..<28 {
            spawnParticle(heat: min(max(displayedHeat / 100, 0), 1), burst: true)
        }
    }

    private func drawSparks(encoder: MTLRenderCommandEncoder, uniforms: inout FireUniforms) {
        guard !particles.isEmpty else { return }
        let vertices = particles.map {
            SparkVertex(
                position: $0.position,
                life: min(max($0.age / $0.lifetime, 0), 1),
                seed: $0.seed
            )
        }
        guard let buffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<SparkVertex>.stride * vertices.count,
            options: .storageModeShared
        ) else { return }

        encoder.setRenderPipelineState(sparkPipeline)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<FireUniforms>.stride, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<FireUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
    }

    private func updateParticles(deltaTime: Float, heat: Float) {
        let normalized = min(max(heat / 100, 0), 1)
        let driftTime = Float(CACurrentMediaTime() - startTime)

        for index in particles.indices {
            particles[index].age += deltaTime
            let curl = sin(driftTime * 1.7 + particles[index].seed * 19 + particles[index].position.y * 8)
            particles[index].velocity.x += curl * deltaTime * (0.015 + normalized * 0.035)
            particles[index].velocity.y += deltaTime * 0.012
            particles[index].position += particles[index].velocity * deltaTime
        }
        particles.removeAll { $0.age >= $0.lifetime || $0.position.y > 1.08 }

        let rate = (1.5 + 58 * pow(normalized, 1.45)) * qualityScale
        spawnAccumulator += rate * deltaTime
        while spawnAccumulator >= 1 {
            spawnParticle(heat: normalized, burst: false)
            spawnAccumulator -= 1
        }

        let burstChance = deltaTime * (0.012 + normalized * 0.055)
        if Float.random(in: 0...1) < burstChance {
            let count = Int.random(in: 4...max(5, Int(5 + normalized * 10)))
            for _ in 0..<count { spawnParticle(heat: normalized, burst: true) }
        }

        let capacity = Int(24 + 196 * qualityScale)
        if particles.count > capacity {
            particles.removeFirst(particles.count - capacity)
        }
    }

    private func spawnParticle(heat: Float, burst: Bool) {
        let spread: Float = burst ? 0.085 : 0.045
        let speedBoost: Float = burst ? 1.65 : 1
        let particle = SparkParticle(
            position: SIMD2(0.5 + Float.random(in: -spread...spread), 0.32 + Float.random(in: -0.015...0.06)),
            velocity: SIMD2(
                Float.random(in: -0.035...0.035) * speedBoost,
                Float.random(in: (0.10 + heat * 0.08)...(0.18 + heat * 0.28)) * speedBoost
            ),
            age: 0,
            lifetime: Float.random(in: 0.7...(1.5 + heat * 1.7)),
            seed: Float.random(in: 0...1)
        )
        particles.append(particle)
    }

    private func recordPerformance(frameTime: Double, view: MTKView) {
        sampledFrameTime += frameTime
        sampledFrames += 1
        metricsElapsed += frameTime

        if sampledFrames >= 90 {
            let average = sampledFrameTime / Double(sampledFrames)
            let target = view.preferredFramesPerSecond == 30 ? 1.0 / 30.0 : 1.0 / 60.0
            if average > target * 1.28 {
                qualityScale = max(0.35, qualityScale - 0.12)
            } else if average < target * 1.08 {
                qualityScale = min(1, qualityScale + 0.04)
            }
            sampledFrameTime = 0
            sampledFrames = 0
        }

        guard metricsElapsed >= 30 else { return }
        metricsElapsed = 0
        let fps = frameTime > 0 ? 1.0 / frameTime : 0
        let thermal = ProcessInfo.processInfo.thermalState.rawValue
        let battery = UIDevice.current.batteryLevel
        logger.info(
            "fps=\(fps, format: .fixed(precision: 1)) particles=\(self.particles.count) quality=\(self.qualityScale, format: .fixed(precision: 2)) lowPower=\(ProcessInfo.processInfo.isLowPowerModeEnabled) thermal=\(thermal) battery=\(battery, format: .fixed(precision: 2))"
        )
    }

    private static func makePipeline(
        device: MTLDevice,
        view: MTKView,
        vertex: MTLFunction,
        fragment: MTLFunction
    ) throws -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }
}


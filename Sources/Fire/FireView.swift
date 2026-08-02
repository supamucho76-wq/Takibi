import MetalKit
import SwiftUI

struct FireView: UIViewRepresentable {
    let heat: Double
    let isActive: Bool
    let burnSequence: Int
    let tint: FlameTint

    final class Coordinator {
        var renderer: FireRenderer?
        var lastBurnSequence = 0
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return MTKView(frame: .zero)
        }

        let view = MTKView(frame: .zero, device: device)
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.layer.isOpaque = false
        view.framebufferOnly = true
        view.enableSetNeedsDisplay = false
        view.isPaused = !isActive
        view.preferredFramesPerSecond = ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 60

        let renderer = FireRenderer(view: view)
        renderer.heat = Float(heat)
        renderer.flameTint = SIMD4(Float(tint.red), Float(tint.green), Float(tint.blue), 1)
        renderer.isActive = isActive
        context.coordinator.renderer = renderer
        context.coordinator.lastBurnSequence = burnSequence
        view.delegate = renderer
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.renderer?.heat = Float(heat)
        context.coordinator.renderer?.flameTint = SIMD4(Float(tint.red), Float(tint.green), Float(tint.blue), 1)
        context.coordinator.renderer?.isActive = isActive
        if burnSequence != context.coordinator.lastBurnSequence {
            context.coordinator.renderer?.triggerWoodBurst()
            context.coordinator.lastBurnSequence = burnSequence
        }
        view.preferredFramesPerSecond = ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 60
        view.isPaused = !isActive
    }

    static func dismantleUIView(_ view: MTKView, coordinator: Coordinator) {
        coordinator.renderer?.isActive = false
        view.isPaused = true
        view.delegate = nil
    }
}


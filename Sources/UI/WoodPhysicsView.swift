import AVFoundation
import QuartzCore
import SpriteKit
import SwiftUI
import UIKit

@MainActor
final class WoodThrowController: ObservableObject {
    fileprivate weak var scene: WoodPhysicsScene?
    private var pendingLaunches: [WoodLaunchRequest] = []

    func launchWood(_ wood: WoodType, from releasePoint: CGPoint, swipe: CGSize) {
        pendingLaunches.append(WoodLaunchRequest(wood: wood, releasePoint: releasePoint, swipe: swipe))
        flushIfReady()
    }

    fileprivate func attach(_ scene: WoodPhysicsScene) {
        self.scene = scene
        flushIfReady()
    }

    fileprivate func sceneWasResized() {
        flushIfReady()
    }

    private func flushIfReady() {
        guard let scene, scene.size.width > 1, scene.size.height > 1, !pendingLaunches.isEmpty else { return }
        let queued = pendingLaunches
        pendingLaunches.removeAll()
        for (index, request) in queued.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.16) { [weak scene] in
                scene?.launchLog(request)
            }
        }
    }
}

fileprivate struct WoodLaunchRequest {
    let wood: WoodType
    let releasePoint: CGPoint
    let swipe: CGSize
}

struct WoodPhysicsView: UIViewRepresentable {
    @ObservedObject var controller: WoodThrowController
    let isActive: Bool
    let onLogLanded: () -> Void

    final class Coordinator {
        fileprivate let scene = WoodPhysicsScene()
        fileprivate var onLogLanded: (() -> Void)?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WoodPhysicsSKView {
        let view = WoodPhysicsSKView(frame: .zero)
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.isOpaque = false
        view.preferredFramesPerSecond = ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 60

        let scene = context.coordinator.scene
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        scene.onFirstImpact = { [weak coordinator = context.coordinator] in coordinator?.onLogLanded?() }
        context.coordinator.onLogLanded = onLogLanded
        view.presentScene(scene)
        controller.attach(scene)

        view.onLayout = { [weak controller, weak scene] size in
            guard size.width > 1, size.height > 1, let scene else { return }
            scene.size = size
            controller?.sceneWasResized()
        }
        return view
    }

    func updateUIView(_ view: WoodPhysicsSKView, context: Context) {
        view.preferredFramesPerSecond = ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 60
        view.isPaused = !isActive
        context.coordinator.onLogLanded = onLogLanded
        controller.attach(context.coordinator.scene)
        if view.bounds.width > 1, view.bounds.height > 1 {
            context.coordinator.scene.size = view.bounds.size
            controller.sceneWasResized()
        }
    }
}

final class WoodPhysicsSKView: SKView {
    var onLayout: ((CGSize) -> Void)?
    override func layoutSubviews() { super.layoutSubviews(); onLayout?(bounds.size) }
    override func didMoveToWindow() { super.didMoveToWindow(); onLayout?(bounds.size) }
}

fileprivate final class WoodPhysicsScene: SKScene, SKPhysicsContactDelegate {
    private enum Category {
        static let log: UInt32 = 1 << 0
        static let pile: UInt32 = 1 << 1
        static let boundary: UInt32 = 1 << 2
    }

    private let impactAudio = WoodImpactAudio()
    var onFirstImpact: (() -> Void)?
    private var colliders: [SKNode] = []
    private var restingLogs: [SKNode] = []
    private var lastImpactTime: TimeInterval = 0

    override init() {
        super.init(size: .zero)
        physicsWorld.gravity = CGVector(dx: 0, dy: -920)
        physicsWorld.contactDelegate = self
        anchorPoint = .zero
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func didChangeSize(_ oldSize: CGSize) { super.didChangeSize(oldSize); rebuildPileColliders() }

    func launchLog(_ request: WoodLaunchRequest) {
        guard size.width > 1, size.height > 1 else { return }
        let wood = request.wood
        let visualSize = CGSize(width: min(size.width * 0.31, 126), height: 58)
        let log = WoodSpriteFactory.makeNode(for: wood, size: visualSize)
        log.name = "thrown-log"
        log.userData = ["hasLanded": false]
        log.zPosition = 100
        let x = min(max(request.releasePoint.x, visualSize.width * 0.55), size.width - visualSize.width * 0.55)
        let y = min(max(size.height - request.releasePoint.y, size.height * 0.19), size.height * 0.58)
        log.position = CGPoint(x: x, y: y)
        log.zRotation = CGFloat.random(in: -0.20...0.20)

        let body = SKPhysicsBody(rectangleOf: WoodSpriteFactory.physicsSize(for: wood, base: visualSize))
        body.mass = max(0.065, 0.092 * CGFloat(wood.weight))
        body.friction = 0.92
        body.restitution = CGFloat.random(in: 0.28...0.43)
        body.linearDamping = 0.08
        body.angularDamping = 0.46
        body.allowsRotation = true
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = Category.log
        body.collisionBitMask = Category.log
        body.contactTestBitMask = Category.log
        let upwardSpeed = min(max(-request.swipe.height * 4.4, 330), 820)
        let horizontalSpeed = min(max(request.swipe.width * 3.2, -300), 300)
        body.velocity = CGVector(
            dx: horizontalSpeed,
            dy: upwardSpeed
        )
        body.angularVelocity = CGFloat.random(in: -8.2...8.2) + request.swipe.width * 0.025
        log.physicsBody = body

        addChild(log)
        addMotionTrail(to: log, tint: wood.flameTint)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak body] in
            body?.collisionBitMask = Category.log | Category.pile | Category.boundary
            body?.contactTestBitMask = Category.log | Category.pile | Category.boundary
        }

        restingLogs.append(log)
        trimOldLogs()
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        guard categories & Category.log != 0, contact.collisionImpulse > 0.32 else { return }
        let logNode = contact.bodyA.categoryBitMask == Category.log ? contact.bodyA.node : contact.bodyB.node

        if categories & Category.pile != 0, logNode?.userData?["hasLanded"] as? Bool != true {
            logNode?.userData?["hasLanded"] = true
            onFirstImpact?()
        }

        let now = CACurrentMediaTime()
        guard now - lastImpactTime > 0.065 else { return }
        lastImpactTime = now
        let strength = min(max(contact.collisionImpulse / 18, 0.20), 1)
        UIImpactFeedbackGenerator(style: strength > 0.58 ? .rigid : .light).impactOccurred(intensity: strength)
        impactAudio.play(intensity: Float(strength))
        makeImpactParticles(at: contact.contactPoint, strength: strength)
    }

    private func addMotionTrail(to log: SKNode, tint: FlameTint) {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 28
        emitter.particleLifetime = 0.24
        emitter.particleLifetimeRange = 0.08
        emitter.particlePositionRange = CGVector(dx: 34, dy: 12)
        emitter.particleScale = 0.055
        emitter.particleScaleRange = 0.02
        emitter.particleScaleSpeed = -0.18
        emitter.particleAlpha = 0.30
        emitter.particleAlphaSpeed = -1.20
        emitter.particleColor = UIColor(red: CGFloat(tint.red), green: CGFloat(tint.green), blue: CGFloat(tint.blue), alpha: 1)
        emitter.particleColorBlendFactor = 1
        emitter.particleSpeed = 8
        emitter.targetNode = self
        emitter.zPosition = 90
        log.addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 1.10), .run { emitter.particleBirthRate = 0 }, .wait(forDuration: 0.35), .removeFromParent()]))
    }

    private func makeImpactParticles(at point: CGPoint, strength: CGFloat) {
        let ring = SKShapeNode(circleOfRadius: 7 + 6 * strength)
        ring.fillColor = .clear
        ring.strokeColor = UIColor.orange.withAlphaComponent(0.72)
        ring.lineWidth = 2
        ring.position = point
        ring.zPosition = 110
        addChild(ring)
        ring.run(.sequence([.group([.scale(to: 2.5, duration: 0.18), .fadeOut(withDuration: 0.22)]), .removeFromParent()]))

        for _ in 0..<Int(5 + strength * 7) {
            let chip = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 3...7), height: 2), cornerRadius: 1)
            chip.fillColor = Bool.random() ? .systemOrange : UIColor(red: 0.45, green: 0.20, blue: 0.06, alpha: 1)
            chip.strokeColor = .clear
            chip.position = point
            chip.zPosition = 112
            addChild(chip)
            let dx = CGFloat.random(in: -48...48) * strength
            let dy = CGFloat.random(in: 24...76) * strength
            chip.run(.sequence([.group([.moveBy(x: dx, y: dy, duration: 0.32), .rotate(byAngle: CGFloat.random(in: -3.2...3.2), duration: 0.32), .fadeOut(withDuration: 0.38)]), .removeFromParent()]))
        }
    }

    private func rebuildPileColliders() {
        colliders.forEach { $0.removeFromParent() }
        colliders.removeAll()
        guard size.width > 1, size.height > 1 else { return }
        let centerX = size.width / 2
        let pileY = size.height * 0.285
        addCollider(size: CGSize(width: min(size.width * 0.74, 292), height: 16), position: CGPoint(x: centerX, y: pileY - 24), angle: 0, category: Category.pile)
        addCollider(size: CGSize(width: 160, height: 20), position: CGPoint(x: centerX - 28, y: pileY), angle: 0.22, category: Category.pile)
        addCollider(size: CGSize(width: 154, height: 20), position: CGPoint(x: centerX + 24, y: pileY + 8), angle: -0.24, category: Category.pile)
        addCollider(size: CGSize(width: 10, height: size.height * 0.52), position: CGPoint(x: 4, y: size.height * 0.28), angle: 0, category: Category.boundary)
        addCollider(size: CGSize(width: 10, height: size.height * 0.52), position: CGPoint(x: size.width - 4, y: size.height * 0.28), angle: 0, category: Category.boundary)
    }

    private func addCollider(size: CGSize, position: CGPoint, angle: CGFloat, category: UInt32) {
        let node = SKNode()
        node.position = position
        node.zRotation = angle
        node.physicsBody = SKPhysicsBody(rectangleOf: size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.friction = 0.96
        node.physicsBody?.restitution = 0.22
        node.physicsBody?.categoryBitMask = category
        node.physicsBody?.collisionBitMask = Category.log
        node.physicsBody?.contactTestBitMask = Category.log
        addChild(node)
        colliders.append(node)
    }

    private func trimOldLogs() {
        guard restingLogs.count > 9 else { return }
        let overflow = restingLogs.count - 9
        let removed = restingLogs.prefix(overflow)
        restingLogs.removeFirst(overflow)
        removed.forEach { $0.run(.sequence([.fadeOut(withDuration: 0.45), .removeFromParent()])) }
    }
}

fileprivate final class WoodImpactAudio {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var sampleSeed: UInt32 = 0x4B_55_42_45

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? engine.start()
        player.play()
    }

    func play(intensity: Float) {
        if !engine.isRunning { try? engine.start() }
        if !player.isPlaying { player.play() }
        guard let buffer = makeBuffer(intensity: intensity) else { return }
        player.scheduleBuffer(buffer)
        if intensity > 0.60, let echo = makeBuffer(intensity: intensity * 0.44) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.075) { [weak player] in player?.scheduleBuffer(echo) }
        }
    }

    private func makeBuffer(intensity: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(5_400)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount), let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount
        let level = min(max(intensity, 0.16), 0.92)
        let pitch = Float.random(in: 118...205)
        for frame in 0..<Int(frameCount) {
            let time = Float(frame) / 44_100
            let decay = Float(Foundation.exp(Double(-27 * time)))
            sampleSeed = 1_664_525 &* sampleSeed &+ 1_013_904_223
            let noise = Float(sampleSeed & 0xFFFF) / Float(0xFFFF) * 2 - 1
            let knock = sin(2 * .pi * pitch * time) + 0.54 * sin(2 * .pi * pitch * 2.37 * time)
            samples[frame] = (knock * 0.36 + noise * 0.25) * decay * level
        }
        return buffer
    }
}

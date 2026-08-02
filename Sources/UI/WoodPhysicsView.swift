import AVFoundation
import QuartzCore
import SpriteKit
import SwiftUI
import UIKit

struct WoodPhysicsView: UIViewRepresentable {
    let burnSequence: Int
    let isActive: Bool
    let onLogLanded: () -> Void

    final class Coordinator {
        fileprivate let scene = WoodPhysicsScene()
        fileprivate var lastBurnSequence = 0
        fileprivate var pendingThrows = 0
        fileprivate var onLogLanded: (() -> Void)?

        fileprivate func resize(to size: CGSize) {
            guard size.width > 1, size.height > 1 else { return }
            if scene.size != size {
                scene.size = size
            }
            flushThrows()
        }

        fileprivate func enqueueThrows(_ count: Int) {
            pendingThrows += max(0, count)
            flushThrows()
        }

        private func flushThrows() {
            guard scene.size.width > 1, scene.size.height > 1, pendingThrows > 0 else { return }
            let count = pendingThrows
            pendingThrows = 0

            for index in 0..<count {
                let currentScene = scene
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.13) { [weak currentScene] in
                    currentScene?.throwLog()
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WoodPhysicsSKView {
        let view = WoodPhysicsSKView(frame: .zero)
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.isOpaque = false
        view.preferredFramesPerSecond = ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 60

        let scene = context.coordinator.scene
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        scene.onFirstImpact = { [weak coordinator = context.coordinator] in
            coordinator?.onLogLanded?()
        }
        view.presentScene(scene)
        context.coordinator.lastBurnSequence = burnSequence
        context.coordinator.onLogLanded = onLogLanded

        view.onLayout = { [weak coordinator = context.coordinator] size in
            coordinator?.resize(to: size)
        }
        return view
    }

    func updateUIView(_ view: WoodPhysicsSKView, context: Context) {
        view.preferredFramesPerSecond = ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 60
        view.isPaused = !isActive
        context.coordinator.onLogLanded = onLogLanded
        context.coordinator.resize(to: view.bounds.size)

        if burnSequence > context.coordinator.lastBurnSequence {
            let newThrows = burnSequence - context.coordinator.lastBurnSequence
            context.coordinator.lastBurnSequence = burnSequence
            context.coordinator.enqueueThrows(newThrows)
        } else if burnSequence < context.coordinator.lastBurnSequence {
            context.coordinator.lastBurnSequence = burnSequence
        }
    }
}

final class WoodPhysicsSKView: SKView {
    var onLayout: ((CGSize) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?(bounds.size)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onLayout?(bounds.size)
    }
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
    private var restingLogs: [SKSpriteNode] = []
    private var lastImpactTime: TimeInterval = 0

    override init() {
        super.init(size: .zero)
        physicsWorld.gravity = CGVector(dx: 0, dy: -860)
        physicsWorld.contactDelegate = self
        anchorPoint = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        rebuildPileColliders()
    }

    func throwLog() {
        guard size.width > 1, size.height > 1 else { return }

        let texture = SKTexture(imageNamed: "WoodLog")
        texture.filteringMode = .linear

        let log = SKSpriteNode(texture: texture)
        log.name = "thrown-log"
        log.userData = ["hasLanded": false]
        log.size = CGSize(width: min(size.width * 0.27, 108), height: 48)
        log.zPosition = 20

        let startsLeft = Bool.random()
        let startX = size.width * (startsLeft ? CGFloat.random(in: 0.26...0.42) : CGFloat.random(in: 0.58...0.74))
        log.position = CGPoint(x: startX, y: max(54, size.height * 0.065))
        log.zRotation = CGFloat.random(in: -0.48...0.48)
        log.setScale(0.72)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: log.size.width * 0.82, height: log.size.height * 0.48))
        body.mass = CGFloat.random(in: 0.075...0.105)
        body.friction = 0.86
        body.restitution = CGFloat.random(in: 0.25...0.38)
        body.linearDamping = 0.11
        body.angularDamping = 0.52
        body.allowsRotation = true
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = Category.log
        body.collisionBitMask = Category.log | Category.boundary
        body.contactTestBitMask = Category.log | Category.boundary

        let targetX = size.width * 0.5 + CGFloat.random(in: -46...46)
        let flightTime = CGFloat.random(in: 0.72...0.88)
        body.velocity = CGVector(
            dx: (targetX - startX) / flightTime,
            dy: CGFloat.random(in: 640...710)
        )
        body.angularVelocity = CGFloat.random(in: -7.4...7.4)
        log.physicsBody = body

        addChild(log)
        log.run(.scale(to: CGFloat.random(in: 0.94...1.04), duration: 0.22))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) { [weak body] in
            body?.collisionBitMask = Category.log | Category.pile | Category.boundary
            body?.contactTestBitMask = Category.log | Category.pile | Category.boundary
        }
        restingLogs.append(log)
        trimOldLogs()
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        guard categories & Category.log != 0 else { return }
        guard contact.collisionImpulse > 0.45 else { return }

        let logNode = contact.bodyA.categoryBitMask == Category.log ? contact.bodyA.node : contact.bodyB.node
        if categories & Category.pile != 0,
           logNode?.userData?["hasLanded"] as? Bool != true {
            logNode?.userData?["hasLanded"] = true
            onFirstImpact?()
        }

        let now = CACurrentMediaTime()
        guard now - lastImpactTime > 0.075 else { return }
        lastImpactTime = now

        let strength = min(max(contact.collisionImpulse / 22, 0.18), 0.92)
        UIImpactFeedbackGenerator(style: strength > 0.55 ? .rigid : .light)
            .impactOccurred(intensity: strength)
        impactAudio.play(intensity: Float(strength))
        makeImpactParticles(at: contact.contactPoint, strength: strength)
    }

    private func makeImpactParticles(at point: CGPoint, strength: CGFloat) {
        let flash = SKShapeNode(circleOfRadius: 5 + 4 * strength)
        flash.fillColor = UIColor.orange.withAlphaComponent(0.42 + 0.26 * strength)
        flash.strokeColor = .clear
        flash.position = point
        flash.zPosition = 24
        addChild(flash)
        flash.run(.sequence([
            .group([.scale(to: 2.2, duration: 0.16), .fadeOut(withDuration: 0.20)]),
            .removeFromParent()
        ]))

        let chipCount = Int(3 + strength * 5)
        for _ in 0..<chipCount {
            let chip = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 2...5), height: 2), cornerRadius: 1)
            chip.fillColor = Bool.random() ? UIColor.systemOrange : UIColor(red: 0.52, green: 0.24, blue: 0.08, alpha: 1)
            chip.strokeColor = .clear
            chip.position = point
            chip.zPosition = 25
            addChild(chip)

            let dx = CGFloat.random(in: -34...34) * strength
            let dy = CGFloat.random(in: 18...58) * strength
            chip.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: 0.28),
                    .rotate(byAngle: CGFloat.random(in: -2.6...2.6), duration: 0.28),
                    .fadeOut(withDuration: 0.32)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func rebuildPileColliders() {
        colliders.forEach { $0.removeFromParent() }
        colliders.removeAll()
        guard size.width > 1, size.height > 1 else { return }

        let centerX = size.width / 2
        let pileY = size.height * 0.285
        addCollider(size: CGSize(width: min(size.width * 0.72, 282), height: 14), position: CGPoint(x: centerX, y: pileY - 22), angle: 0, category: Category.pile)
        addCollider(size: CGSize(width: 154, height: 18), position: CGPoint(x: centerX - 24, y: pileY), angle: 0.21, category: Category.pile)
        addCollider(size: CGSize(width: 148, height: 18), position: CGPoint(x: centerX + 20, y: pileY + 7), angle: -0.22, category: Category.pile)

        addCollider(size: CGSize(width: 10, height: size.height * 0.42), position: CGPoint(x: 4, y: size.height * 0.24), angle: 0, category: Category.boundary)
        addCollider(size: CGSize(width: 10, height: size.height * 0.42), position: CGPoint(x: size.width - 4, y: size.height * 0.24), angle: 0, category: Category.boundary)
    }

    private func addCollider(size: CGSize, position: CGPoint, angle: CGFloat, category: UInt32) {
        let node = SKNode()
        node.position = position
        node.zRotation = angle
        node.physicsBody = SKPhysicsBody(rectangleOf: size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.friction = 0.94
        node.physicsBody?.restitution = 0.19
        node.physicsBody?.categoryBitMask = category
        node.physicsBody?.collisionBitMask = Category.log
        node.physicsBody?.contactTestBitMask = Category.log
        addChild(node)
        colliders.append(node)
    }

    private func trimOldLogs() {
        guard restingLogs.count > 8 else { return }
        let overflow = restingLogs.count - 8
        let removed = restingLogs.prefix(overflow)
        restingLogs.removeFirst(overflow)
        for log in removed {
            log.run(.sequence([.fadeOut(withDuration: 0.38), .removeFromParent()]))
        }
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
    }

    private func makeBuffer(intensity: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(4_850)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        let level = min(max(intensity, 0.16), 0.90)
        let pitch = Float.random(in: 145...215)
        for frame in 0..<Int(frameCount) {
            let time = Float(frame) / 44_100
            let decay = Float(Foundation.exp(Double(-31 * time)))
            sampleSeed = 1_664_525 &* sampleSeed &+ 1_013_904_223
            let noise = Float(sampleSeed & 0xFFFF) / Float(0xFFFF) * 2 - 1
            let knock = sin(2 * .pi * pitch * time) + 0.44 * sin(2 * .pi * pitch * 2.31 * time)
            samples[frame] = (knock * 0.34 + noise * 0.24) * decay * level
        }
        return buffer
    }
}

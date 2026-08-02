import QuartzCore
import SpriteKit
import SwiftUI
import UIKit

struct WoodPhysicsView: UIViewRepresentable {
    let burnSequence: Int
    let isActive: Bool

    final class Coordinator {
        fileprivate let scene = WoodPhysicsScene()
        var lastBurnSequence = 0
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: .zero)
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.isOpaque = false
        view.preferredFramesPerSecond = ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 60

        let scene = context.coordinator.scene
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        view.presentScene(scene)
        context.coordinator.lastBurnSequence = burnSequence
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        view.preferredFramesPerSecond = ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 60
        view.isPaused = !isActive

        if view.bounds.size.width > 0, view.bounds.size.height > 0,
           context.coordinator.scene.size != view.bounds.size {
            context.coordinator.scene.size = view.bounds.size
        }

        if burnSequence != context.coordinator.lastBurnSequence {
            context.coordinator.scene.throwLog()
            context.coordinator.lastBurnSequence = burnSequence
        }
    }
}

fileprivate final class WoodPhysicsScene: SKScene, SKPhysicsContactDelegate {
    private enum Category {
        static let log: UInt32 = 1 << 0
        static let pile: UInt32 = 1 << 1
    }

    private var colliders: [SKNode] = []
    private var restingLogs: [SKSpriteNode] = []
    private var lastImpactTime: TimeInterval = 0

    override init() {
        super.init(size: .zero)
        physicsWorld.gravity = CGVector(dx: 0, dy: -520)
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
        guard size.width > 0, size.height > 0 else { return }

        let texture = SKTexture(imageNamed: "WoodLog")
        let log = SKSpriteNode(texture: texture)
        log.name = "thrown-log"
        log.size = CGSize(width: min(size.width * 0.28, 112), height: 54)
        log.zPosition = 4

        let entersFromLeft = Bool.random()
        log.position = CGPoint(
            x: entersFromLeft ? -log.size.width * 0.55 : size.width + log.size.width * 0.55,
            y: size.height * CGFloat.random(in: 0.43...0.53)
        )
        log.zRotation = CGFloat.random(in: -0.7...0.7)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: log.size.width * 0.86, height: log.size.height * 0.52))
        body.mass = 0.085
        body.friction = 0.82
        body.restitution = 0.28
        body.linearDamping = 0.12
        body.angularDamping = 0.48
        body.allowsRotation = true
        body.categoryBitMask = Category.log
        body.collisionBitMask = Category.log | Category.pile
        body.contactTestBitMask = Category.pile
        body.velocity = CGVector(
            dx: entersFromLeft ? CGFloat.random(in: 300...390) : CGFloat.random(in: -390 ... -300),
            dy: CGFloat.random(in: 105...185)
        )
        body.angularVelocity = CGFloat.random(in: -6.8...6.8)
        log.physicsBody = body

        addChild(log)
        restingLogs.append(log)
        trimOldLogs()
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        guard categories & Category.log != 0, categories & Category.pile != 0 else { return }

        let now = CACurrentMediaTime()
        guard now - lastImpactTime > 0.11 else { return }
        lastImpactTime = now

        let strength = min(max(contact.collisionImpulse / 18, 0.25), 0.85)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: strength)

        let spark = SKShapeNode(circleOfRadius: 7)
        spark.fillColor = UIColor.orange.withAlphaComponent(0.58)
        spark.strokeColor = .clear
        spark.position = contact.contactPoint
        spark.zPosition = 5
        addChild(spark)
        spark.run(.sequence([
            .group([.scale(to: 2.4, duration: 0.18), .fadeOut(withDuration: 0.22)]),
            .removeFromParent()
        ]))
    }

    private func rebuildPileColliders() {
        colliders.forEach { $0.removeFromParent() }
        colliders.removeAll()
        guard size.width > 0, size.height > 0 else { return }

        let centerX = size.width / 2
        let pileY = size.height * 0.285
        addCollider(size: CGSize(width: min(size.width * 0.68, 270), height: 12), position: CGPoint(x: centerX, y: pileY - 18), angle: 0)
        addCollider(size: CGSize(width: 148, height: 18), position: CGPoint(x: centerX - 18, y: pileY), angle: 0.20)
        addCollider(size: CGSize(width: 142, height: 18), position: CGPoint(x: centerX + 16, y: pileY + 7), angle: -0.20)
    }

    private func addCollider(size: CGSize, position: CGPoint, angle: CGFloat) {
        let node = SKNode()
        node.position = position
        node.zRotation = angle
        node.physicsBody = SKPhysicsBody(rectangleOf: size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.friction = 0.94
        node.physicsBody?.restitution = 0.20
        node.physicsBody?.categoryBitMask = Category.pile
        node.physicsBody?.collisionBitMask = Category.log
        node.physicsBody?.contactTestBitMask = Category.log
        addChild(node)
        colliders.append(node)
    }

    private func trimOldLogs() {
        guard restingLogs.count > 6 else { return }
        let overflow = restingLogs.count - 6
        let removed = restingLogs.prefix(overflow)
        restingLogs.removeFirst(overflow)
        for log in removed {
            log.run(.sequence([.fadeOut(withDuration: 0.35), .removeFromParent()]))
        }
    }
}

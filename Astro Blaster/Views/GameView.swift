//
//  GameView.swift
//  Astro Blaster
//

import Foundation
import SwiftUI
import SpriteKit

// MARK: - Physics Categories

struct PhysicsCategory {
    static let none: UInt32      = 0
    static let spaceship: UInt32 = 1 << 0
    static let laser: UInt32     = 1 << 1
    static let enemy: UInt32     = 1 << 2
    static let upgrade: UInt32   = 1 << 3
}

// MARK: - Upgrade Enum

enum UpgradeType: CaseIterable {
    case health
    case rapidFire
    case dualShot
}

// MARK: - Spaceship Model

struct Spaceship {
    var fireRate: TimeInterval = 0.8
    var health: Int = 3
    var hasDualShot: Bool = false

    mutating func apply(_ upgrade: UpgradeType) {
        switch upgrade {
        case .health:
            health += 1
        case .rapidFire:
            fireRate = max(0.12, fireRate - 0.03)
        case .dualShot:
            hasDualShot = true
        }
    }
}

// MARK: - Asteroid Model

struct Asteroid {
    let health: Int
    let speed: CGFloat
    let scale: CGFloat
    let asset: String

    static func random(difficulty: CGFloat) -> Asteroid {
        Asteroid(
            health: max(1, Int(difficulty * 0.8)),
            speed: 60 + difficulty * 20,
            scale: 0.045,
            asset: "asteroid\(Int.random(in: 1...7))"
        )
    }
}

// MARK: - Game Scene

final class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: Configuration

    private let maxDifficulty: CGFloat
    private let difficultyTimeConstant: CGFloat = 90.0 // ~5 min to plateau

    // MARK: State

    private let shipNode = SKSpriteNode(imageNamed: "spaceship")
    private var ship = Spaceship()

    private var dragStartX: CGFloat = 0

    private var lastFire: TimeInterval = 0
    private var elapsed: TimeInterval = 0

    private var lastEnemySpawn: TimeInterval = 0
    private var lastUpgradeDrop: TimeInterval = 0
    private var nextUpgradeDelay: TimeInterval = Double.random(in: 13...16)

    private var shootLeftNext = true

    // MARK: HUD

    private let hud = SKLabelNode(fontNamed: "Menlo")

    // MARK: Init

    init(maxDifficulty: CGFloat) {
        self.maxDifficulty = maxDifficulty
        super.init(size: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Lifecycle

    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        backgroundColor = .black
        setupShip()
        setupHUD()
    }

    // MARK: Setup

    private func setupShip() {
        shipNode.setScale(0.1)
        shipNode.zRotation = .pi
        shipNode.position = CGPoint(x: 0, y: -size.height * 0.4)

        shipNode.physicsBody = SKPhysicsBody(rectangleOf: shipNode.size)
        shipNode.physicsBody?.affectedByGravity = false
        shipNode.physicsBody?.categoryBitMask = PhysicsCategory.spaceship
        shipNode.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        shipNode.physicsBody?.collisionBitMask = PhysicsCategory.none

        addChild(shipNode)
    }

    private func setupHUD() {
        hud.fontSize = 12
        hud.horizontalAlignmentMode = .left
        hud.verticalAlignmentMode = .top
        hud.position = CGPoint(
            x: -size.width / 2 + 10,
            y: size.height / 2 - 50
        )
        hud.zPosition = 100
        addChild(hud)
    }

    // MARK: Difficulty

    private func difficulty() -> CGFloat {
        let t = CGFloat(elapsed)
        let value = maxDifficulty * (1 - exp(-t / difficultyTimeConstant))
        return min(value, maxDifficulty)
    }

    // MARK: Game Loop

    override func update(_ currentTime: TimeInterval) {
        elapsed += 1.0 / 60.0

        fireLasers(currentTime)
        spawnEnemies(currentTime)
        spawnUpgrades(currentTime)

        moveEnemies()
        moveUpgrades()
        updateHUD()
    }

    // MARK: Lasers

    private func fireLasers(_ time: TimeInterval) {
        guard time - lastFire >= ship.fireRate else { return }
        lastFire = time

        if ship.hasDualShot {
            spawnLaser(asset: "BlasterschussLinks", xOffset: -12)
            spawnLaser(asset: "BlasterschussRechts", xOffset: 12)
        } else {
            let asset = shootLeftNext ? "BlasterschussLinks" : "BlasterschussRechts"
            spawnLaser(asset: asset, xOffset: shootLeftNext ? -30 : 30)
            shootLeftNext.toggle()
        }
    }

    private func spawnLaser(asset: String, xOffset: CGFloat) {
        let laser = SKSpriteNode(imageNamed: asset)
        laser.setScale(0.05)
        laser.position = CGPoint(
            x: shipNode.position.x + xOffset,
            y: shipNode.position.y + shipNode.size.height / 2
        )

        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size)
        laser.physicsBody?.velocity = CGVector(dx: 0, dy: 900)
        laser.physicsBody?.affectedByGravity = false
        laser.physicsBody?.categoryBitMask = PhysicsCategory.laser
        laser.physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.upgrade
        laser.physicsBody?.collisionBitMask = PhysicsCategory.none

        addChild(laser)

        laser.run(.sequence([
            .wait(forDuration: 2.0),
            .removeFromParent()
        ]))
    }

    // MARK: Enemies

    private func spawnEnemies(_ time: TimeInterval) {
        guard time - lastEnemySpawn > 1.0 else { return }
        lastEnemySpawn = time

        let asteroid = Asteroid.random(difficulty: difficulty())
        let node = SKSpriteNode(imageNamed: asteroid.asset)
        node.name = "enemy"
        node.setScale(asteroid.scale)

        let half = node.size.width / 2
        let minX = -size.width / 2 + half
        let maxX = size.width / 2 - half

        node.position = CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: size.height / 2 + node.size.height
        )

        node.userData = ["hp": asteroid.health, "speed": asteroid.speed]

        node.physicsBody = SKPhysicsBody(circleOfRadius: half)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        node.physicsBody?.contactTestBitMask = PhysicsCategory.laser
        node.physicsBody?.collisionBitMask = PhysicsCategory.none

        addChild(node)

        let direction: CGFloat = Bool.random() ? 1 : -1
        let rotations = CGFloat.random(in: 0.5...1.0)
        let fallDuration = size.height / asteroid.speed

        node.run(
            .rotate(
                byAngle: direction * rotations * .pi * 2,
                duration: TimeInterval(fallDuration)
            )
        )
    }

    private func moveEnemies() {
        enumerateChildNodes(withName: "enemy") { node, _ in
            if let speed = node.userData?["speed"] as? CGFloat {
                node.position.y -= speed * (1 / 60)
            }
            if node.position.y < -self.size.height / 2 - node.frame.height {
                node.removeFromParent()
            }
        }
    }

    // MARK: Upgrades

    private func spawnUpgrades(_ time: TimeInterval) {
        guard time - lastUpgradeDrop > nextUpgradeDelay else { return }

        lastUpgradeDrop = time
        nextUpgradeDelay = Double.random(in: 13...16)

        let type = UpgradeType.allCases.randomElement()!
        let node = SKSpriteNode(color: .cyan, size: CGSize(width: 30, height: 30))
        node.name = "upgrade"
        node.userData = ["type": type, "speed": CGFloat(80)]

        node.position = CGPoint(x: 0, y: size.height / 2)

        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.upgrade
        node.physicsBody?.contactTestBitMask = PhysicsCategory.laser
        node.physicsBody?.collisionBitMask = PhysicsCategory.none

        addChild(node)
    }

    private func moveUpgrades() {
        enumerateChildNodes(withName: "upgrade") { node, _ in
            if let speed = node.userData?["speed"] as? CGFloat {
                node.position.y -= speed * (1 / 60)
            }
            if node.position.y < -self.size.height / 2 - node.frame.height {
                node.removeFromParent()
            }
        }
    }

    // MARK: Collisions

    func didBegin(_ contact: SKPhysicsContact) {
        guard let a = contact.bodyA.node,
              let b = contact.bodyB.node else { return }

        let enemy = a.name == "enemy" ? a : b.name == "enemy" ? b : nil
        let upgrade = a.name == "upgrade" ? a : b.name == "upgrade" ? b : nil
        let laser = contact.bodyA.categoryBitMask == PhysicsCategory.laser ? a : b

        if let enemy = enemy {
            flashWhite(enemy)
            if let hp = enemy.userData?["hp"] as? Int, hp > 1 {
                enemy.userData?["hp"] = hp - 1
            } else {
                enemy.removeFromParent()
            }
        }

        if let upgrade = upgrade,
           let type = upgrade.userData?["type"] as? UpgradeType {
            ship.apply(type)
            upgrade.removeFromParent()
        }

        laser.removeFromParent()
    }

    // MARK: Damage Feedback

    private func flashWhite(_ node: SKNode) {
        node.run(.sequence([
            .colorize(with: .white, colorBlendFactor: 1, duration: 0.05),
            .colorize(withColorBlendFactor: 0, duration: 0.05)
        ]))
    }

    // MARK: HUD

    private var hudLines: [SKLabelNode] = []

    private func updateHUD() {
        // Remove old lines
        hudLines.forEach { $0.removeFromParent() }
        hudLines.removeAll()

        let enemyCount = children.filter { $0.name == "enemy" }.count
        let laserCount = children.filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.laser }.count

        let texts = [
            "Enemies: \(enemyCount)",
            "Lasers: \(laserCount)",
            "Difficulty: \(String(format: "%.2f", difficulty()))",
            "", // blank line for separation
            "Ship Stats:",
            "Health: \(ship.health)",
            "Fire Rate: \(String(format: "%.2f", ship.fireRate)) s",
            "Dual Shot: \(ship.hasDualShot)"
        ]

        for (i, text) in texts.enumerated() {
            let line = SKLabelNode(fontNamed: "Menlo")
            line.text = text
            line.fontSize = 12
            line.horizontalAlignmentMode = .left
            line.verticalAlignmentMode = .top
            line.position = CGPoint(
                x: -size.width / 2 + 10,
                y: size.height / 2 - 10 - CGFloat(i) * 14
            )
            line.zPosition = 100
            addChild(line)
            hudLines.append(line)
        }
    }

    // MARK: Input

    func beginDrag() {
        dragStartX = shipNode.position.x
    }

    func dragShip(by deltaX: CGFloat) {
        let proposedX = dragStartX + deltaX
        let half = shipNode.size.width / 2

        shipNode.position.x = min(
            max(proposedX, -size.width / 2 + half),
            size.width / 2 - half
        )
    }
}

// MARK: - SwiftUI View

struct GameView: View {

    private let scene: GameScene

    init(maxDifficulty: CGFloat) {
        self.scene = GameScene(maxDifficulty: maxDifficulty)
    }

    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .gesture(
                    DragGesture()
                        .onChanged { scene.dragShip(by: $0.translation.width) }
                        .onEnded { _ in scene.beginDrag() }
                )
                .onAppear {
                    scene.size = geo.size
                    scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                    scene.beginDrag()
                }
        }
    }
}

#Preview {
    GameView(maxDifficulty: 5)
}

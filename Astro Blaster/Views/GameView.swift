//
//  GameView.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 09.12.25.
//


import Foundation
import SwiftUI
import SpriteKit

// MARK: - Physics Categories

// for collisions
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
    var fireRate: TimeInterval = 0.8 // in seconds
    var health: Int = 3
    var hasDualShot: Bool = false

    // update stats according to collected upgrade
    mutating func apply(_ upgrade: UpgradeType) {
        switch upgrade {
        case .health:
            health += 1
        case .rapidFire:
            fireRate = max(0.12, fireRate - 0.09)
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

    // generate random asteroids based on game state
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

    private let maxDifficulty: CGFloat // can be set from outside
    private let difficultyTimeConstant: CGFloat = 90.0 // ~5 min to plateau

    // MARK: State

    private let shipNode = SKSpriteNode(imageNamed: "spaceship")
    private var ship = Spaceship()

    private var dragStartX: CGFloat = 0

    private var lastFire: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var elapsed: TimeInterval = 0

    private var lastEnemySpawn: TimeInterval = 0
    private var lastUpgradeDrop: TimeInterval = 0
    private var nextUpgradeDelay: TimeInterval = Double.random(in: 13...16)

    // flag for alternate fire
    private var shootLeftNext = true

    // MARK: HUD

    private let hud = SKLabelNode(fontNamed: "Menlo")

    // MARK: Init

    init(maxDifficulty: CGFloat) {
        self.maxDifficulty = maxDifficulty // different levels
        super.init(size: .zero) // setting size later
    }

    // to conform to SKScene
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Lifecycle

    // gets called when SKView adds or removes an interaction from its interaction array
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self // for detecting collisions
        backgroundColor = .black // TODO: background images
        setupShip()
        setupHUD() // debugging
    }

    // MARK: Setup

    private func setupShip() {
        shipNode.setScale(0.1)
        shipNode.zRotation = .pi
        shipNode.position = CGPoint(x: 0, y: -size.height * 0.4)

        shipNode.physicsBody = SKPhysicsBody(rectangleOf: shipNode.size)
        shipNode.physicsBody?.affectedByGravity = false // no gravity since the ship only moves horizontally
        shipNode.physicsBody?.categoryBitMask = PhysicsCategory.spaceship
        shipNode.physicsBody?.contactTestBitMask = PhysicsCategory.enemy // checks for enemy contact and then calls the corresponding delegate didBegin method (in this case didBegin(_ contact:) TODO: add collision with upgrade
        shipNode.physicsBody?.collisionBitMask = PhysicsCategory.none // no physical collisions

        addChild(shipNode) // append it to the SKScene
    }

    // debugging hud
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
        let t = CGFloat(elapsed) // time elapsed since game start
        let value = maxDifficulty * (1 - exp(-t / difficultyTimeConstant)) // approaches maxDifficulty * 1 at around 300 seconds, smaller difficultyTimeConstant makes it harder since it approaches 1 earlier
        return min(value, maxDifficulty) // only go up to maxDifficulty
    }

    // MARK: Game Loop
    
    // helper which computes passed time to account for different framerates
    private func computeDeltaTime(currentTime: TimeInterval) -> TimeInterval {
        let delta = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 1.0 / 60.0
        lastUpdateTime = currentTime
        return delta
    }

    override func update(_ currentTime: TimeInterval) {
        
        let delta = computeDeltaTime(currentTime: currentTime)
        elapsed += delta
        
        fireLasers(currentTime)
        spawnEnemies(currentTime)
        spawnUpgrades(currentTime)

        moveEnemies(delta: delta)
        moveUpgrades(delta: delta)
        updateHUD()
    }

    // MARK: Lasers

    private func fireLasers(_ time: TimeInterval) {
        
        // only fire if enough time has passed (safety measure)
        guard time - lastFire >= ship.fireRate else { return }
        lastFire = time

        if ship.hasDualShot {
            spawnLaser(asset: "BlasterschussLinks", xOffset: -12) // TODO: design choice
            spawnLaser(asset: "BlasterschussRechts", xOffset: 12) // TODO: design choice
        } else {
            // use alternating assets
            let asset = shootLeftNext ? "BlasterschussLinks" : "BlasterschussRechts"
            spawnLaser(asset: asset, xOffset: shootLeftNext ? -30 : 30)
            shootLeftNext.toggle() // toggle flag
        }
    }

    private func spawnLaser(asset: String, xOffset: CGFloat) {
        let laser = SKSpriteNode(imageNamed: asset)
        laser.setScale(0.05) // asset way too large
        laser.position = CGPoint(
            x: shipNode.position.x + xOffset,
            y: shipNode.position.y + shipNode.size.height / 2
        )

        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size)
        laser.physicsBody?.velocity = CGVector(dx: 0, dy: 900)
        laser.physicsBody?.affectedByGravity = false
        laser.physicsBody?.categoryBitMask = PhysicsCategory.laser
        laser.physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.upgrade // look for contact with either enemies or upgrade bit masks
        laser.physicsBody?.collisionBitMask = PhysicsCategory.none // no collisions

        addChild(laser)

        // run the sequence
        laser.run(.sequence([
            .wait(forDuration: 2.0),
            .removeFromParent() // delete after it leaves the screen to prevent memory leaks
        ]))
    }

    // MARK: Enemies

    private func spawnEnemies(_ time: TimeInterval) {
        
        // only spawn when enough time is passed
        guard time - lastEnemySpawn > 1.0 else { return }
        lastEnemySpawn = time

        let asteroid = Asteroid.random(difficulty: difficulty())
        let node = SKSpriteNode(imageNamed: asteroid.asset)
        node.name = "enemy"
        node.setScale(asteroid.scale) // differently sized asteroids

        // determine screen boundaries
        let half = node.size.width / 2
        let minX = -size.width / 2 + half
        let maxX = size.width / 2 - half

        // spawn at random x locations out of screen
        node.position = CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: size.height / 2 + node.size.height
        )

        node.userData = ["hp": asteroid.health, "speed": asteroid.speed]

        node.physicsBody = SKPhysicsBody(circleOfRadius: half)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        node.physicsBody?.contactTestBitMask = PhysicsCategory.laser // look for contact with laser
        node.physicsBody?.collisionBitMask = PhysicsCategory.none // no collisions

        addChild(node) // add to SKScene

        // random rotation animation for more inversive gameplay (how exciting)
        let direction: CGFloat = Bool.random() ? 1 : -1 // either left or right
        let rotations = CGFloat.random(in: 0.5...1.0) // half to full rotation
        let fallDuration = size.height / asteroid.speed

        // execute the rotation animation
        node.run(
            .rotate(
                byAngle: direction * rotations * .pi * 2,
                duration: TimeInterval(fallDuration)
            )
        )
    }

    private func moveEnemies(delta: TimeInterval) {
        // group enemies
        enumerateChildNodes(withName: "enemy") { node, _ in
            if let speed = node.userData?["speed"] as? CGFloat {
                node.position.y -= speed * CGFloat(delta) // make the asteroids fall
            }
            if node.position.y < -self.size.height / 2 - node.frame.height {
                node.removeFromParent() // delete if it went through
            }
        }
    }

    // MARK: Upgrades

    private func spawnUpgrades(_ time: TimeInterval) {
        guard time - lastUpgradeDrop > nextUpgradeDelay else { return }

        lastUpgradeDrop = time
        nextUpgradeDelay = Double.random(in: 13...16)

        let type = UpgradeType.allCases.randomElement()! // omg look its a force unwrap (shiver me timbers)
        let node = SKSpriteNode(color: .cyan, size: CGSize(width: 30, height: 30)) //TODO: insert actual asset for upgrade
        node.name = "upgrade"
        node.userData = ["type": type, "speed": CGFloat(80)]

        node.position = CGPoint(x: 0, y: size.height / 2 + node.size.height) // spawn outside of screen

        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.upgrade
        node.physicsBody?.contactTestBitMask = PhysicsCategory.laser // look for contact with lasers
        node.physicsBody?.collisionBitMask = PhysicsCategory.none // no collisions

        addChild(node) // add to SKScene
    }

    // same as move enemies
    private func moveUpgrades(delta: TimeInterval) {
        enumerateChildNodes(withName: "upgrade") { node, _ in
            if let speed = node.userData?["speed"] as? CGFloat {
                node.position.y -= speed * CGFloat(delta)
            }
            if node.position.y < -self.size.height / 2 - node.frame.height {
                node.removeFromParent()
            }
        }
    }

    // MARK: Collisions

    // gets called when contact is recognized between contactTestBitMask and categoryBitMask (if AND is non-zero)
    func didBegin(_ contact: SKPhysicsContact) {
        // get both participants
        guard let a = contact.bodyA.node,
              let b = contact.bodyB.node else { return }

        let enemy = a.name == "enemy" ? a : b.name == "enemy" ? b : nil // check if either is an enemy
        let upgrade = a.name == "upgrade" ? a : b.name == "upgrade" ? b : nil // check if either is an upgrade
        let laser = contact.bodyA.categoryBitMask == PhysicsCategory.laser ? a : b // since only laser makes contact, it must be one of the two TODO: check if one of the participants is the spaceship since it can also have contact with enemies, currently its treated like a laser

        // if we hit an enemy (if enemy is not null)
        if let enemy = enemy {
            flashWhite(enemy) // damage animation
            if let hp = enemy.userData?["hp"] as? Int, hp > 1 {
                enemy.userData?["hp"] = hp - 1 // if it still has HP afterwards, reduce it by one
            } else {
                enemy.removeFromParent() // delete if zero HP remaining
            }
        }
        
        // if its an upgrade (if upgrade is not null)
        if let upgrade = upgrade,
           let type = upgrade.userData?["type"] as? UpgradeType {
            ship.apply(type) // apply the upgrade
            upgrade.removeFromParent() // delete the node
        }

        laser.removeFromParent() // delete the laser //TODO: currently if the ship makes contact with an asteroid luckily the asteroid is b which delets the asteroid instead (do we sell this as a feature? XD)
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
        // Remove old lines from previous frames
        hudLines.forEach { $0.removeFromParent() } // awesome cool smart sparse way of writing closures right
        hudLines.removeAll()

        // count enemies and lasers currently within the SKScene
        let enemyCount = children.filter { $0.name == "enemy" }.count
        let laserCount = children.filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.laser }.count

        // logging
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

        // prevent clamping, dont let the ship go out of bounds
        shipNode.position.x = min(
            max(proposedX, -size.width / 2 + half),
            size.width / 2 - half
        )
    }
}

// MARK: - SwiftUI View

struct GameView: View {

    private let scene: GameScene

    // set difficulty
    init(maxDifficulty: CGFloat) {
        self.scene = GameScene(maxDifficulty: maxDifficulty)
    }

    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .statusBarHidden(true) // hide clock, wifi, ...
                .gesture(
                    DragGesture() // react to drag
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


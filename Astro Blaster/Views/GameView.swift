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

struct PhysicsCategory {
    static let none: UInt32       = 0
    static let spaceship: UInt32  = 1 << 0
    static let laser: UInt32      = 1 << 1
    static let enemy: UInt32      = 1 << 2
}

// MARK: - Upgrade Enum

enum Upgrade {
    case health
    case rapidFire
    case multiLaser
}

// MARK: - Spaceship Model

struct Spaceship {
    
    private(set) var fireRate: TimeInterval
    private(set) var health: Int
    private(set) var laserCount: Int
    
    private let minFireRate: TimeInterval = 0.1
    private let maxFireRate: TimeInterval = 1.0
    private let minHealth: Int = 1
    private let maxLaserCount: Int = 5
    
    init(fireRate: TimeInterval = 0.4, health: Int = 3, laserCount: Int = 1) {
        self.fireRate = fireRate
        self.health = health
        self.laserCount = laserCount
    }
    
    mutating func increaseFireRate(by delta: TimeInterval = 0.05) {
        fireRate = max(minFireRate, fireRate - delta)
    }
    
    mutating func decreaseFireRate(by delta: TimeInterval = 0.05) {
        fireRate = min(maxFireRate, fireRate + delta)
    }
    
    mutating func increaseHealth(by amount: Int = 1) {
        health += amount
    }
    
    mutating func decreaseHealth(by amount: Int = 1) {
        health = max(minHealth, health - amount)
    }
    
    mutating func increaseLaserCount(by amount: Int = 1) {
        laserCount = min(maxLaserCount, laserCount + amount)
    }
    
    mutating func decreaseLaserCount(by amount: Int = 1) {
        laserCount = max(1, laserCount - amount)
    }
}

// MARK: - Asteroid Model

struct Asteroid {
    var health: Int
    var size: CGFloat
    var speed: CGFloat
    var asset: String
    
    // Big asteroid
    static func big(scale: CGFloat) -> Asteroid {
        return Asteroid(
            health: Int(5 * scale),
            size: CGFloat.random(in: 0.07...0.1) * scale,
            speed: 50 / scale,
            asset: "asteroid"
        )
    }
    
    // Medium asteroid
    static func medium(scale: CGFloat) -> Asteroid {
        return Asteroid(
            health: Int(3 * scale),
            size: CGFloat.random(in: 0.05...0.07) * scale,
            speed: 80 / scale,
            asset: "asteroid"
        )
    }
    
    // Small asteroid
    static func small(scale: CGFloat) -> Asteroid {
        return Asteroid(
            health: Int(1 * scale),
            size: CGFloat.random(in: 0.03...0.05) * scale,
            speed: 120 / scale,
            asset: "asteroid"
        )
    }
}

// MARK: - SpriteKit Scene

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private let spaceshipNode = SKSpriteNode(imageNamed: "spaceship")
    private var spaceship = Spaceship()
    
    private var dragStartX: CGFloat = 0
    private var lastFireTime: TimeInterval = 0
    private var lastEnemySpawnTime: TimeInterval = 0
    private var gameScale: CGFloat = 1.0 // scales difficulty over time
    
    private let enemySpawnInterval: TimeInterval = 1.0
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        physicsWorld.contactDelegate = self
        
        setupSpaceshipNode()
    }
    
    // MARK: - Setup
    
    private func setupSpaceshipNode() {
        spaceshipNode.zRotation = .pi
        spaceshipNode.setScale(0.1)
        spaceshipNode.zPosition = 1
        spaceshipNode.position = CGPoint(x: 0, y: -size.height * 0.4)
        
        spaceshipNode.physicsBody = SKPhysicsBody(rectangleOf: spaceshipNode.size)
        spaceshipNode.physicsBody?.isDynamic = true
        spaceshipNode.physicsBody?.affectedByGravity = false
        spaceshipNode.physicsBody?.allowsRotation = false
        spaceshipNode.physicsBody?.categoryBitMask = PhysicsCategory.spaceship
        spaceshipNode.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        spaceshipNode.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        addChild(spaceshipNode)
    }
    
    // MARK: - Input
    
    func beginHorizontalDrag() {
        dragStartX = spaceshipNode.position.x
    }
    
    func dragSpaceship(by deltaX: CGFloat) {
        let proposedX = dragStartX + deltaX
        let halfWidth = spaceshipNode.size.width / 2
        spaceshipNode.position.x = min(
            max(proposedX, -size.width / 2 + halfWidth),
            size.width / 2 - halfWidth
        )
    }
    
    // MARK: - Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        fireLasersIfNeeded(currentTime: currentTime)
        spawnEnemiesIfNeeded(currentTime: currentTime)
        moveEnemies(deltaTime: 1.0 / 60.0)
        
        // Gradually increase difficulty over time
        gameScale += 0.0005
    }
    
    // MARK: - Laser System
    
    private func fireLasersIfNeeded(currentTime: TimeInterval) {
        guard currentTime - lastFireTime >= spaceship.fireRate else { return }
        lastFireTime = currentTime
        spawnLasers()
    }
    
    private func spawnLasers() {
        let spacing: CGFloat = 20
        let offset = -(CGFloat(spaceship.laserCount - 1) / 2) * spacing
        
        for i in 0..<spaceship.laserCount {
            let laser = SKSpriteNode(imageNamed: "laser_demo")
            laser.setScale(0.05)
            laser.position = CGPoint(
                x: spaceshipNode.position.x + offset + CGFloat(i) * spacing,
                y: spaceshipNode.position.y + spaceshipNode.size.height / 2
            )
            
            laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size)
            laser.physicsBody?.isDynamic = true
            laser.physicsBody?.affectedByGravity = false
            laser.physicsBody?.velocity = CGVector(dx: 0, dy: 800)
            laser.physicsBody?.linearDamping = 0
            laser.physicsBody?.categoryBitMask = PhysicsCategory.laser
            laser.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
            laser.physicsBody?.collisionBitMask = PhysicsCategory.none
            
            addChild(laser)
            
            laser.run(.sequence([
                .wait(forDuration: size.height / 800),
                .removeFromParent()
            ]))
        }
    }
    
    // MARK: - Enemy System
    
    private func spawnEnemiesIfNeeded(currentTime: TimeInterval) {
        guard currentTime - lastEnemySpawnTime >= enemySpawnInterval else { return }
        lastEnemySpawnTime = currentTime
        
        // Randomly select big, medium, or small asteroid
        let rand = Int.random(in: 0...2)
        var asteroid: Asteroid
        switch rand {
        case 0: asteroid = Asteroid.big(scale: gameScale)
        case 1: asteroid = Asteroid.medium(scale: gameScale)
        default: asteroid = Asteroid.small(scale: gameScale)
        }
        
        spawnAsteroid(asteroid)
    }
    
    private func spawnAsteroid(_ asteroid: Asteroid) {
        let node = SKSpriteNode(imageNamed: asteroid.asset)
        node.name = "enemy"
        node.setScale(asteroid.size)
        
        let xPos = CGFloat.random(in: -size.width/2 + node.size.width/2 ... size.width/2 - node.size.width/2)
        node.position = CGPoint(x: xPos, y: size.height / 2 + node.size.height/2)
        
        node.userData = ["health": asteroid.health, "speed": asteroid.speed]
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = true
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        node.physicsBody?.contactTestBitMask = PhysicsCategory.laser
        node.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        addChild(node)
    }
    
    private func moveEnemies(deltaTime: CGFloat) {
        enumerateChildNodes(withName: "enemy") { node, _ in
            guard let speed = node.userData?["speed"] as? CGFloat else { return }
            node.position.y -= speed * deltaTime
            if node.position.y < -self.size.height/2 - node.frame.height {
                node.removeFromParent()
            }
        }
    }
    
    // MARK: - Collisions
    
    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if mask == PhysicsCategory.laser | PhysicsCategory.enemy {
            if let enemy = contact.bodyA.categoryBitMask == PhysicsCategory.enemy ? contact.bodyA.node : contact.bodyB.node {
                if let health = enemy.userData?["health"] as? Int, health > 1 {
                    enemy.userData?["health"] = health - 1
                } else {
                    enemy.removeFromParent()
                }
            }
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
        }
    }
    
    // MARK: - Upgrades
    
    func applyUpgrade(_ upgrade: Upgrade) {
        switch upgrade {
        case .health: spaceship.increaseHealth()
        case .rapidFire: spaceship.increaseFireRate()
        case .multiLaser: spaceship.increaseLaserCount()
        }
    }
}

// MARK: - SwiftUI View

struct GameView: View {
    
    private let scene = GameScene()
    
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .gesture(
                    DragGesture()
                        .onChanged { scene.dragSpaceship(by: $0.translation.width) }
                        .onEnded { _ in scene.beginHorizontalDrag() }
                )
                .onAppear {
                    scene.size = geometry.size
                    scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                    scene.scaleMode = .resizeFill
                    scene.beginHorizontalDrag()
                }
        }
    }
}

#Preview {
    GameView()
}

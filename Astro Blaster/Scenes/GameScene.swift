//
//  GameScene.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 18.12.25.
//

import SpriteKit
import SwiftUI
import AVFoundation

final class GameScene: SKScene, SKPhysicsContactDelegate, AVAudioPlayerDelegate {

    // MARK: Configuration
    private let difficultyTimeConstant: CGFloat = 90.0 // ~5 min to plateau
    weak var viewModel: GameViewModel?
    
    // MARK: Audio
    private var backgroundMusic: AVAudioPlayer?
    private var didPlayIntro = false

    // MARK: State
    private let shipNode = SKSpriteNode(imageNamed: "spaceship")
    private let health1 = SKSpriteNode(imageNamed: "heart")
    private let health2 = SKSpriteNode(imageNamed: "heart")
    private let health3 = SKSpriteNode(imageNamed: "heart")
    private var upgradeText = ""
    private var ship = Spaceship()
    private var dragStartX: CGFloat = 0
    private var lastFire: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private var lastEnemySpawn: TimeInterval = 0
    private var lastUpgradeDrop: TimeInterval = 0
    private var nextUpgradeDelay: TimeInterval = Double.random(in: 13...16)
    private var shootLeftNext = true
    
    
    // MARK: Active Upgrades
    private var overdriveRemaining: TimeInterval = 0
    private var overdriveBaseDuration: TimeInterval = 5.0
    private let overdriveBonusDuration: TimeInterval = 2.0
    private let minFireRate: TimeInterval = 0.12
    private var preOverdriveFireRate: TimeInterval?
    
    private let overdriveBackground = SKShapeNode(rectOf: CGSize(width: 120, height: 10), cornerRadius: 4)
    private let overdriveFill = SKShapeNode(rectOf: CGSize(width: 116, height: 6), cornerRadius: 3)
    

    // MARK: HUD & Score Labels
    private let hud = SKLabelNode(fontNamed: "ArcadeInterlaced")
    private var scoreLabel = SKLabelNode(fontNamed: "ArcadeInterlaced")
    private var highscoreLabel = SKLabelNode(fontNamed: "ArcadeInterlaced")
    private var hudLines: [SKLabelNode] = []

    // MARK: Lifecycle
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self // for detecting collisions
        backgroundColor = .black.withAlphaComponent(0)
        
        playBackgroundMusic()
        setupShip()
        setupHUD() // debugging
        setupOverdriveUI()
        setupScore()
        layoutOverdriveUI()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutScoreLabels()
    }

    // MARK: Setup functions
    private func setupShip() {
        shipNode.setScale(0.066)
        shipNode.zRotation = .pi
        shipNode.position = CGPoint(x: 0, y: -size.height * 0.4)
        shipNode.physicsBody = SKPhysicsBody(rectangleOf: shipNode.size)
        shipNode.physicsBody?.affectedByGravity = false
        shipNode.physicsBody?.categoryBitMask = PhysicsCategory.spaceship
        shipNode.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        shipNode.physicsBody?.collisionBitMask = PhysicsCategory.none

        addChild(shipNode)
        
        let leftEmitter = createContrail(at: -shipNode.size.width * 0.25)
        shipNode.addChild(leftEmitter)
        let rightEmitter = createContrail(at: shipNode.size.width * 0.25)
        shipNode.addChild(rightEmitter)
    }

    func createContrail(at offsetX: CGFloat) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "particle")
        emitter.particleColor = .cyan
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBirthRate = 200
        emitter.particleLifetime = 1.0
        emitter.particleLifetimeRange = 0.2
        emitter.particleSpeed = 200
        emitter.particleSpeedRange = 40
        emitter.particleAlpha = 0.7
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -0.7
        emitter.particleScale = 0.03
        emitter.particleScaleRange = 0.02
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi / 8
        emitter.targetNode = self
        emitter.position = CGPoint(x: offsetX, y: -shipNode.size.height / 2 + 480)
        return emitter
    }
    
    func createUpgradeGlowCircle(radius: CGFloat = 50) -> SKShapeNode {
        let glow = SKShapeNode(circleOfRadius: radius)
        glow.strokeColor = .yellow
        glow.lineWidth = 4
        glow.fillColor = .clear
        glow.alpha = 0.6
        glow.zPosition = -1  // behind the upgrade
        glow.glowWidth = 10

        // Pulsate animation
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.8)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.8)
        let pulse = SKAction.repeatForever(.sequence([scaleUp, scaleDown]))
        glow.run(pulse)
        
        return glow
    }

    private func setupHUD() {
        hud.fontSize = 12
        hud.horizontalAlignmentMode = .left
        hud.verticalAlignmentMode = .top
        hud.position = CGPoint(x: -size.width / 2 + 10, y: size.height / 2 - 50)
        hud.zPosition = 100
        addChild(hud)
    }

    private func setupScore() {
        scoreLabel.fontSize = 14
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 200
        addChild(scoreLabel)

        highscoreLabel.fontSize = 12
        highscoreLabel.fontColor = .white
        highscoreLabel.horizontalAlignmentMode = .left
        highscoreLabel.verticalAlignmentMode = .center
        highscoreLabel.zPosition = 200
        addChild(highscoreLabel)

        layoutScoreLabels()
    }

    private func setupOverdriveUI() {
        overdriveBackground.fillColor = .white
        overdriveBackground.strokeColor = .clear
        overdriveBackground.zPosition = 300
        overdriveBackground.isHidden = true
        overdriveFill.fillColor = .green
        overdriveFill.strokeColor = .clear
        overdriveFill.zPosition = 301
        overdriveBackground.addChild(overdriveFill)
        addChild(overdriveBackground)
    }

    private func layoutScoreLabels() {
        scoreLabel.position = CGPoint(x: size.width / 8 - 200, y: size.height / 2 - 70)
        highscoreLabel.position = CGPoint(x: scoreLabel.position.x, y: scoreLabel.position.y - 20)
    }

    private func difficulty() -> CGFloat {
        let t = CGFloat(elapsed)
        let maxDifficulty = viewModel?.maxDifficulty ?? 5.0
        let value = maxDifficulty * (1 - exp(-t / difficultyTimeConstant))
        return min(value, maxDifficulty)
    }

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        guard let vm = viewModel, !vm.isGameOver else { return }
        
        let delta = computeDeltaTime(currentTime: currentTime)
        elapsed += delta

        vm.updateScore(points: 1) // Passive score over time
        scoreLabel.text = "Score: \(vm.scoreValue)"
        highscoreLabel.text = "High: \(vm.highscore)"

        fireLasers(currentTime)
        spawnEnemies(currentTime)
        spawnUpgrades(currentTime)
        moveEnemies(delta: delta)
        moveUpgrades(delta: delta)
        updateHUD()
        updateHealth()
        printUpgradesToScreen()
        updateOverdrive(delta: delta)
        layoutOverdriveUI()
    }

    private func computeDeltaTime(currentTime: TimeInterval) -> TimeInterval {
        let delta = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 1.0 / 60.0
        lastUpdateTime = currentTime
        return delta
    }
    
    private func updateHealth() {
        health1.removeFromParent()
        health2.removeFromParent()
        health3.removeFromParent()
        if ship.health == 3 {
            health1.setScale(0.02)
            health1.zRotation = 0
            health1.position = CGPoint(x: scoreLabel.position.x + health1.size.width / 2 , y: scoreLabel.position.y - 40)
            addChild(health1)
            health2.setScale(0.02)
            health2.zRotation = 0
            health2.position = CGPoint(x: scoreLabel.position.x + health1.size.width / 2 + 20 , y: scoreLabel.position.y - 40)
            addChild(health2)
            health3.setScale(0.02)
            health3.zRotation = 0
            health3.position = CGPoint(x: scoreLabel.position.x + health1.size.width / 2 + 40 , y: scoreLabel.position.y - 40)
            addChild(health3)
        } else if ship.health == 2 {
            health1.setScale(0.02)
            health1.zRotation = 0
            health1.position = CGPoint(x: scoreLabel.position.x + health1.size.width / 2 , y: scoreLabel.position.y - 40)
            addChild(health1)
            health2.setScale(0.02)
            health2.zRotation = 0
            health2.position = CGPoint(x: scoreLabel.position.x + health1.size.width / 2 + 20 , y: scoreLabel.position.y - 40)
            addChild(health2)
        } else if ship.health == 1 {
            health1.setScale(0.02)
            health1.zRotation = 0
            health1.position = CGPoint(x: scoreLabel.position.x + health1.size.width / 2 , y: scoreLabel.position.y - 40)
            addChild(health1)
        } else {
            
        }
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
        laser.setScale(0.03)
        laser.position = CGPoint(x: shipNode.position.x + xOffset, y: shipNode.position.y + shipNode.size.height / 2)
        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size)
        laser.physicsBody?.velocity = CGVector(dx: 0, dy: 900)
        laser.physicsBody?.affectedByGravity = false
        laser.physicsBody?.categoryBitMask = PhysicsCategory.laser
        laser.physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.upgrade
        laser.physicsBody?.collisionBitMask = PhysicsCategory.none
        addChild(laser)
        laser.run(.sequence([.wait(forDuration: 2.0), .removeFromParent()]))
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
        node.position = CGPoint(x: CGFloat.random(in: minX + 15 ... maxX - 15), y: size.height / 2 + node.size.height)
        node.userData = ["hp": asteroid.health, "speed": asteroid.speed]
        node.physicsBody = SKPhysicsBody(circleOfRadius: half)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        node.physicsBody?.contactTestBitMask = PhysicsCategory.laser | PhysicsCategory.spaceship
        node.physicsBody?.collisionBitMask = PhysicsCategory.none
        addChild(node)

        let direction: CGFloat = Bool.random() ? 1 : -1
        let rotations = CGFloat.random(in: 0.5...1.0)
        let fallDuration = size.height / asteroid.speed
        node.run(.rotate(byAngle: direction * rotations * .pi * 2, duration: TimeInterval(fallDuration)))
    }

    private func moveEnemies(delta: TimeInterval) {
        enumerateChildNodes(withName: "enemy") { node, _ in
            if let speed = node.userData?["speed"] as? CGFloat {
                node.position.y -= speed * CGFloat(delta)
            }
            if node.position.y + node.frame.height / 2 < -self.size.height / 2 {
                self.ship.health -= 1
                node.removeFromParent()
                if self.ship.health <= 0 { self.gameOver() }
            }
        }
    }

    // MARK: Upgrades
    private let upgradeWeights: [(type: UpgradeType, weight: Double)] = [
        (.rapidFire, 0.55), (.overdrive, 0.3), (.health, 0.10), (.dualShot, 0.05)
        
    ]

    private func chooseRandomUpgrade() -> UpgradeType {
        let roll = Double.random(in: 0...1)
        var cumulative = 0.0
        // store weights for dynamic filtering
        var filteredUpgrades = upgradeWeights
        
        // dont get dual shot twice since its a persistent upgrade
        if ship.hasDualShot {
            filteredUpgrades.removeLast()
        }
        
        // for simplicity with the design
        if ship.health == 3 {
            filteredUpgrades.remove(at: 2)
        }
        
        for entry in filteredUpgrades {
            cumulative += entry.weight
            if roll <= cumulative { return entry.type }
        }
        return .rapidFire
    }
    
    func spawnUpgrades(_ time: TimeInterval) {
        guard time - lastUpgradeDrop > nextUpgradeDelay else { return }
        lastUpgradeDrop = time
        nextUpgradeDelay = Double.random(in: 13...16)
        let type = chooseRandomUpgrade()
        
        let node = SKSpriteNode(imageNamed: "spacestation")
        node.size = CGSize(width: 80, height: 80)
        node.name = "upgrade"
        node.userData = ["type": type, "speed": CGFloat(80)]
        node.position = CGPoint(x: 0, y: size.height / 2 + node.size.height)
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.upgrade
        node.physicsBody?.contactTestBitMask = PhysicsCategory.laser
        node.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        // Add the glowing circle
        let glow = createUpgradeGlowCircle(radius: 40)
        node.addChild(glow)
        
        addChild(node)
    }
    
    private func printUpgradesToScreen() {
        hudLines.forEach { $0.removeFromParent() }
        hudLines.removeAll()
        let line = SKLabelNode(fontNamed: "ArcadeInterlaced")
        line.text = upgradeText
        line.fontColor = .green
        line.fontSize = 12
        line.horizontalAlignmentMode = .center
        line.position.x = 0
        line.position.y = -(frame.height/4 + 25)
        line.zPosition = 100
        addChild(line)
        hudLines.append(line)
    }

    private func moveUpgrades(delta: TimeInterval) {
        enumerateChildNodes(withName: "upgrade") { node, _ in
            if let speed = node.userData?["speed"] as? CGFloat {
                node.position.y -= speed * CGFloat(delta)
            }
            if node.position.y < -self.size.height / 2 - node.frame.height { node.removeFromParent() }
        }
    }

    // MARK: Collisions
    func didBegin(_ contact: SKPhysicsContact) {
        guard let a = contact.bodyA.node, let b = contact.bodyB.node else { return }
        let enemy = a.name == "enemy" ? a : b.name == "enemy" ? b : nil
        let upgrade = a.name == "upgrade" ? a : b.name == "upgrade" ? b : nil
        let laser = contact.bodyA.categoryBitMask == PhysicsCategory.laser ? a : contact.bodyB.categoryBitMask == PhysicsCategory.laser ? b : nil
        let spaceship = contact.bodyA.categoryBitMask == PhysicsCategory.spaceship ? a : contact.bodyB.categoryBitMask == PhysicsCategory.spaceship ? b : nil

        if let enemy = enemy {
            if let spaceship = spaceship {
                ship.health -= 1
                flashWhite(spaceship)
                enemy.removeFromParent()
                if ship.health <= 0 { self.gameOver() }
                return
            }
            flashWhite(enemy)
            if let hp = enemy.userData?["hp"] as? Int, hp > 1 {
                enemy.userData?["hp"] = hp - 1
            } else {
                enemy.removeFromParent()
                viewModel?.updateScore(points: 10)
            }
        }

        if let upgrade = upgrade, let type = upgrade.userData?["type"] as? UpgradeType {
            if type == .overdrive {
                upgradeText = "Overdrive Active"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.upgradeText = ""
                }
                activateOverdrive()
            } else {
                ship.apply(type)
                upgradeText = "\(type) Gained"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.upgradeText = ""
                }
            }
            upgrade.removeFromParent()
            viewModel?.updateScore(points: 100)
        }
        
        if let laser = laser { laser.removeFromParent() }
    }

    private func activateOverdrive() {
        if overdriveRemaining > 0 {
            overdriveRemaining += overdriveBonusDuration
        } else {
            preOverdriveFireRate = ship.fireRate
            overdriveRemaining = overdriveBaseDuration
            ship.fireRate = minFireRate
        }
        overdriveBackground.isHidden = false
    }

    private func updateOverdrive(delta: TimeInterval) {
        guard overdriveRemaining > 0 else { return }
        overdriveRemaining -= delta
        let progress = max(0, overdriveRemaining) / overdriveBaseDuration
        overdriveFill.xScale = CGFloat(progress)
        if overdriveRemaining <= 0 {
            overdriveRemaining = 0
            overdriveBackground.isHidden = true
            if let previous = preOverdriveFireRate {
                ship.fireRate = previous
                preOverdriveFireRate = nil
            }
        }
    }

    private func flashWhite(_ node: SKNode) {
        node.run(.sequence([
            .colorize(with: .white, colorBlendFactor: 1, duration: 0.05),
            .colorize(withColorBlendFactor: 0, duration: 0.05)
        ]))
    }

    private func updateHUD() {
        hudLines.forEach { $0.removeFromParent() }
        hudLines.removeAll()
        //let enemyCount = children.filter { $0.name == "enemy" }.count
        //let laserCount = children.filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.laser }.count
        //let overdriveText = (overdriveRemaining > 0) ? "Overdrive Active" : "";
        let texts = [
            /*
            "Enemies: \(enemyCount)", "Lasers: \(laserCount)",
            "Difficulty: \(String(format: "%.2f", difficulty()))", "",
            "Ship Stats:", "Health: \(ship.health)",
            "Fire Rate: \(String(format: "%.2f", ship.fireRate)) s", "Dual Shot: \(ship.hasDualShot)",
             */
            ""
        ]
        //DO NOT REMOVE THE I; TO MAKE DEVSTATS VISIBLE WHEN NEEDED!!!
        for (i, text) in texts.enumerated() {
            let line = SKLabelNode(fontNamed: "ArcadeInterlaced")
            line.text = text
            line.fontColor = .green
            line.fontSize = 12
            line.horizontalAlignmentMode = .center
            line.position = CGPoint(x: 0, y: -10 - 12 * CGFloat(i))
            line.zPosition = 100
            addChild(line)
            hudLines.append(line)
        }
    }

    private func layoutOverdriveUI() {
        overdriveBackground.position = CGPoint(x: frame.midX, y: frame.height - frame.height * 1.3)
    }
    
    // MARK: - Play Audio
    private func playBackgroundMusic() {
        guard !didPlayIntro else { return }

        guard let url = Bundle.main.url(
            forResource: "backgroundMusicStart",
            withExtension: "wav"
        ) else {
            print("Intro file not found")
            return
        }
        
        do {
            backgroundMusic = try AVAudioPlayer(contentsOf: url)
            backgroundMusic?.delegate = self
            backgroundMusic?.numberOfLoops = 0
            backgroundMusic?.prepareToPlay()
            backgroundMusic?.play()
            didPlayIntro = true
        } catch {
            print("Failed to play intro music")
        }
    }
    
    private func playLoopingMusic() {
        guard let url = Bundle.main.url(
            forResource: "backgroundMusicLoop",
            withExtension: "wav"
        ) else {
            print("Loop file not found")
            return
        }

        do {
            backgroundMusic = try AVAudioPlayer(contentsOf: url)
            backgroundMusic?.numberOfLoops = -1
            backgroundMusic?.prepareToPlay()
            backgroundMusic?.play()
        } catch {
            print("Failed to play looping music")
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playLoopingMusic()
    }

    private func gameOver() {
        ship.health = 0
        viewModel?.setGameOver()
        backgroundMusic?.stop()
        physicsWorld.speed = 0
    }

    // MARK: Input
    func beginDrag() { dragStartX = shipNode.position.x }
    func dragShip(by deltaX: CGFloat) {
        let proposedX = dragStartX + deltaX
        let half = shipNode.size.width / 2
        shipNode.position.x = min(max(proposedX, -size.width / 2 + half), size.width / 2 - half)
    }

    func reset() {
        ship = Spaceship()
        elapsed = 0
        lastFire = 0
        lastUpdateTime = 0
        lastEnemySpawn = 0
        lastUpgradeDrop = 0
        nextUpgradeDelay = Double.random(in: 13...16)
        shootLeftNext = true
        overdriveRemaining = 0
        preOverdriveFireRate = nil
        physicsWorld.speed = 1.0
        shipNode.position = CGPoint(x: 0, y: -size.height * 0.4)
        enumerateChildNodes(withName: "*") { node, _ in
            if let cat = node.physicsBody?.categoryBitMask, [PhysicsCategory.laser, PhysicsCategory.enemy, PhysicsCategory.upgrade].contains(cat) {
                node.removeFromParent()
            }
        }
        overdriveBackground.isHidden = true
        layoutScoreLabels()
        layoutOverdriveUI()
    }
}



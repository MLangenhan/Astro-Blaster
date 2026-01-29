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

    //Configuration
    private let difficultyTimeConstant: CGFloat = 45.0 // ~2.5 min to reach max difficulty
    var viewModel: GameViewModel?
    
    //Audio
    var backgroundMusic: AVAudioPlayer?
    private var didPlayIntro = false
    
    //Assets
    private let shipNode = SKSpriteNode(imageNamed: "spaceship")
    private var ship = Spaceship() // init model
    private let health1 = SKSpriteNode(imageNamed: "heart")
    private let health2 = SKSpriteNode(imageNamed: "heart")
    private let health3 = SKSpriteNode(imageNamed: "heart")

    //States
    private var upgradeText = ""
    private var dragStartX: CGFloat = 0
    //Timestamp from last Laser Fire
    private var lastFire: TimeInterval = 0
    //Delta from current Time to last Fire if paused
    private var lastFireDelta: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private var lastEnemySpawn: TimeInterval = 0
    private var lastUpgradeDrop: TimeInterval = 0
    private var nextUpgradeDelay: TimeInterval = Double.random(in: 13...16)
    private var shootLeftNext = true
    var soundeffectsEnabled = true
    // Absolute Time when the next Upgrade should Spawn (Scheduled relative to the first Update Tick)
    private var nextUpgradeSpawnAt: TimeInterval?
    // Used for Unpausing the Game and Setting Speed back to original Speed
    private var recoverSpeed: CGFloat = 0
    private var isReady = false
    
    // MARK: Active Upgrades
    private var overdriveRemaining: TimeInterval = 0
    private var overdriveBaseDuration: TimeInterval = 5.0
    private let overdriveBonusDuration: TimeInterval = 2.0
    private let minFireRate: TimeInterval = 0.12
    private var preOverdriveFireRate: TimeInterval?
    
    //Overdrive Timer
    private let overdriveBackground = SKShapeNode(rectOf: CGSize(width: 120, height: 10), cornerRadius: 4)
    private let overdriveFill = SKShapeNode(rectOf: CGSize(width: 116, height: 6), cornerRadius: 3)
    
    // Background
    //Spread into 3 since the original pic is 10000px in height and SK only supports up to 4096px
    private let background1 = SKSpriteNode(imageNamed: "backgroundTop")
    private let background2 = SKSpriteNode(imageNamed: "backgroundMid")
    private let background3 = SKSpriteNode(imageNamed: "backgroundBottom")
    // since the bottom one with the earth shouldnt reappear
    private var loopingBackgrounds: [SKSpriteNode] {
        [background1, background2]
    }

    //HUD & Score Labels
    private let hud = SKLabelNode(fontNamed: "ArcadeInterlaced")
    private var scoreLabel = SKLabelNode(fontNamed: "ArcadeInterlaced")
    private var highscoreLabel = SKLabelNode(fontNamed: "ArcadeInterlaced")
    private var hudLines: [SKLabelNode] = []
    private var hearts: [SKSpriteNode] = []

    // MARK: Lifecycle
    
    //Gets Called when the Scene gets Created
    override func didMove(to view: SKView) {
        if size == .zero {
            size = view.bounds.size
        }
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        backgroundColor = .black
        
        isReady = false
        view.isPaused = true
        
        // preload these
        let atlases = [SKTextureAtlas(named:"Enemies"), SKTextureAtlas(named: "Ship")]
        SKTextureAtlas.preloadTextureAtlases(atlases) { [weak self] in
            guard let self else { return }

            DispatchQueue.main.async {
                //For Detecting Collisions
                self.physicsWorld.contactDelegate = self
                
                //Needs to be done only once
                self.playBackgroundMusic()
                self.setupShip()
                self.setupHUD()
                self.setupOverdriveUI()
                self.setupScore()
                self.setupHearts()
                self.layoutOverdriveUI()
                self.setupBackground()
                
                self.isReady = true
                view.isPaused = false
            }
        }
    }
    
    //Consistency when Scene Size Changes
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutScoreLabels()
    }

    // MARK: Setup Functions
    private func setupShip() {
        shipNode.setScale(0.066)
        shipNode.zRotation = .pi // asset is the wrong way around
        shipNode.position = CGPoint(x: 0, y: -size.height * 0.4)
        shipNode.physicsBody = SKPhysicsBody(rectangleOf: shipNode.size) // set hitbox to rectangle of own size
        shipNode.physicsBody?.affectedByGravity = false // spaceships dont fall down
        shipNode.physicsBody?.categoryBitMask = PhysicsCategory.spaceship // im a spaceship
        shipNode.physicsBody?.contactTestBitMask = PhysicsCategory.enemy // im looking for contact with enemies
        shipNode.physicsBody?.collisionBitMask = PhysicsCategory.none // dont care for collisions

        //Add to Scene
        addChild(shipNode)
        
        //Create Contrail Animation
        let leftEmitter = createContrail(at: -shipNode.size.width * 0.25)
        shipNode.addChild(leftEmitter)
        let rightEmitter = createContrail(at: shipNode.size.width * 0.25)
        shipNode.addChild(rightEmitter)
    }

    //Particle for Contrail behind Ship
    func createContrail(at offsetX: CGFloat) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "particle") // particle "asset"
        emitter.particleColor = .cyan
        emitter.particleColorBlendFactor = 1.0 // amount of particles
        emitter.particleBirthRate = 200
        emitter.particleLifetime = 1.0 // in seconds
        emitter.particleLifetimeRange = 0.2 // 0.8 to 1.2 seconds lifetime
        emitter.particleSpeed = 200
        emitter.particleSpeedRange = 40 // 160 to 240 speed
        emitter.particleAlpha = 0.7 // basically brightness in percent
        emitter.particleAlphaRange = 0.2 // .5 to .9 alpha
        emitter.particleAlphaSpeed = -0.7 // decrease alpha by .7 per second to fade it out
        emitter.particleScale = 0.03
        emitter.particleScaleRange = 0.02 // .01 to .05 scale
        emitter.emissionAngle = -.pi / 2 // flow down
        emitter.emissionAngleRange = .pi / 8 // not calculating the range for this...
        emitter.targetNode = self // append to GameScene
        emitter.position = CGPoint(x: offsetX, y: -shipNode.size.height / 2 + 480)
        return emitter
    }
    
    //Glow Circle around the Upgrade
    func createUpgradeGlowCircle(radius: CGFloat = 50) -> SKShapeNode {
        let glow = SKShapeNode(circleOfRadius: radius) // circle
        glow.strokeColor = .yellow
        glow.lineWidth = 4
        glow.fillColor = .clear // inside transparent
        glow.alpha = 0.6
        glow.zPosition = -1  // behind the upgrade
        glow.glowWidth = 10

        //Pulsate Animation
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.8)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.8)
        let pulse = SKAction.repeatForever(.sequence([scaleUp, scaleDown]))
        glow.run(pulse) // run the animation on the glow node
        
        return glow
    }
    
    //How fast does the Background Scroll
    private var backgroundScrollSpeed: CGFloat {
        //Only if Viemodel is connected and Game not over or paused
        guard let vm = viewModel, !vm.isGameOver, !vm.isGamePaused else { return 0 }
        return 40 + difficulty() * 20   //Scales with Difficulty
    }
    
    //Scrolls the Background
    private func scrollBackground(delta: TimeInterval) {
        let move = backgroundScrollSpeed * CGFloat(delta)

        //Move all Backgrounds
        [background1, background2, background3].forEach {
            $0.position.y -= move
        }

        //Recycle only Looping Backgrounds
        for bg in loopingBackgrounds {

            //Fully below the Screen
            if bg.position.y + bg.size.height / 2 < -size.height / 2 {

                //Find the current top-most looping Background
                let topMostY = loopingBackgrounds
                    .map { $0.position.y + $0.size.height / 2 }
                    .max() ?? 0

                //Place this Background above the last
                bg.position.y = topMostY + bg.size.height / 2
            }
        }
    }
    
    private func setupBackground() {
        //Move to Background
        background1.zPosition = -200
        background2.zPosition = -200
        background3.zPosition = -200

        addChild(background1)
        addChild(background2)
        addChild(background3)
        
        layoutBackground()
    }

    //Used for Displaying Scores
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
        scoreLabel.zPosition = 200 // foreground
        addChild(scoreLabel)

        highscoreLabel.fontSize = 12
        highscoreLabel.fontColor = .white
        highscoreLabel.horizontalAlignmentMode = .left
        highscoreLabel.verticalAlignmentMode = .center
        highscoreLabel.zPosition = 200 // foreground
        addChild(highscoreLabel)

        layoutScoreLabels()
    }
    
    //Used for Displaying remaining Player Health
    private func setupHearts() {
        hearts = [health1, health2, health3]
        for heart in hearts {
            heart.setScale(0.02)
            heart.zRotation = 0
            heart.zPosition = 200 // foreground
            addChild(heart)
        }
        layoutHearts()
    }

    // UI Timer for non-persistent Upgrade
    private func setupOverdriveUI() {
        overdriveBackground.fillColor = .white
        overdriveBackground.strokeColor = .clear
        overdriveBackground.zPosition = 300
        overdriveBackground.isHidden = true
        overdriveFill.fillColor = .green
        overdriveFill.strokeColor = .clear
        //Foreground
        overdriveFill.zPosition = 301
        overdriveBackground.addChild(overdriveFill)
        addChild(overdriveBackground)
    }

    //Score and Highscore
    private func layoutScoreLabels() {
        scoreLabel.position = CGPoint(x: size.width / 8 - 200, y: size.height / 2 - 70)
        highscoreLabel.position = CGPoint(x: scoreLabel.position.x, y: scoreLabel.position.y - 20)
    }
    
    private func layoutHearts() {
        //Position relative to Score Label
        let startX = scoreLabel.position.x + health1.size.width / 2
        let y = scoreLabel.position.y - 40
        for (i, heart) in hearts.enumerated() {
            heart.position = CGPoint(x: startX + CGFloat(i) * 20, y: y)
        }
    }
    
    private func layoutBackground() {
        //Different Sizes since they needed to be Cropped in Order to be used as SpriteKitNode
        let h1 = background1.size.height
        let h2 = background2.size.height
        let h3 = background3.size.height
        
        //Place bottom Image so it is visible at Boot
        background3.position = CGPoint(
            x: 0,
            y: -size.height / 2 + h3 / 2 // since anchor point is in the middle
        )

        // Stack upwards
        background2.position = CGPoint(
            x: 0,
            y: background3.position.y + h3 / 2 + h2 / 2 // ontop of background3
        )

        background1.position = CGPoint(
            x: 0,
            y: background2.position.y + h2 / 2 + h1 / 2 // ontop of background2
        )
    }

    // MARK: Game Scale
    
    //Game Scaling Difficulty over Time
    private func difficulty() -> CGFloat {
        let t = CGFloat(elapsed)
        //Passed by Viewmodel
        let maxDifficulty = viewModel?.maxDifficulty ?? 5.0
        //Plateaus at maxDifficulty
        let value = maxDifficulty * (1 - exp(-t / difficultyTimeConstant))
        //Only up to maxDifficulty
        return min(value, maxDifficulty)
    }

    // MARK: - Update
    
    //Gets called once per Frame
    override func update(_ currentTime: TimeInterval) {
        // only start if all the assets are loaded
        guard isReady else { return }
        guard let vm = viewModel, !vm.isGameOver, !vm.isGamePaused else {
            lastUpdateTime = currentTime
            lastFire = currentTime - lastFireDelta
            return
        } //Check for Viewmodel and if not Game over or paused
        
        guard size.width > 0, size.height > 0 else { return }
        
        //Account for different Frame Rates
        let delta = computeDeltaTime(currentTime: currentTime)
        //Counts elapsed Time to Keep track of how long its been Played
        elapsed += delta

        // Schedule the first Upgrade Spawn relative to the first Scene Tick to Avoid immediate Spawn due to large absolute currentTime
        if nextUpgradeSpawnAt == nil {
            nextUpgradeSpawnAt = currentTime + Double.random(in: 13...16)
        }

        // Passive Score over Time
        vm.updateScore(points: 1)
        scoreLabel.text = "Score: \(vm.scoreValue)"
        highscoreLabel.text = "High: \(vm.highscore)"

        //Updating the Game State
        fireLasers(currentTime)
        spawnEnemies(currentTime)
        
        // Spawn an Upgrade only when the absolute Clock Reaches the scheduled Time
        if let scheduled = nextUpgradeSpawnAt, currentTime >= scheduled {
            spawnUpgrades(currentTime)
            //Reschedule the next Upgrade Spawn relative to the current Time
            nextUpgradeSpawnAt = currentTime + Double.random(in: 13...16)
        }
        
        moveEnemies(delta: delta)
        moveUpgrades(delta: delta)
        updateHealth()
        printUpgradesToScreen()
        //Non-persistent Upgrade
        updateOverdrive(delta: delta)
        layoutOverdriveUI()
        scrollBackground(delta: delta)
    }

    //Account for different Frame Rates
    private func computeDeltaTime(currentTime: TimeInterval) -> TimeInterval {
        let delta = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 1.0 / 60.0 // since lastUpdateTime is initialized with zero, we need to update it at least once with a default fps value since the delta would otherwise be negativew which adds too many difficulties
        lastUpdateTime = currentTime // for next comparison
        return delta
    }
    
    //Toggles Visibility of Hearts based on Ships Health
    private func updateHealth() {
        for (index, heart) in hearts.enumerated() {
            heart.isHidden = index >= ship.health
        }
    }

    // MARK: Lasers
    private func fireLasers(_ time: TimeInterval) {
        lastFireDelta = time - lastFire
        //Only Fire after "fireRate" amount of Time has Passed
        guard time - lastFire >= ship.fireRate else { return }
        lastFire = time

        //If dualshot Upgrade is unlocked Shoot both Lasers at the same Time
        if ship.hasDualShot {
            spawnLaser(asset: "BlasterschussLinks", xOffset: -12)
            spawnLaser(asset: "BlasterschussRechts", xOffset: 12)
        } else {
            //Alternating fire based on shootLeftNext Flag
            let asset = shootLeftNext ? "BlasterschussLinks" : "BlasterschussRechts"
            spawnLaser(asset: asset, xOffset: shootLeftNext ? -30 : 30)
            shootLeftNext.toggle()
        }
        //Laser Sound Effect
        playSFX("laser.wav", volume: 0.2)
    }

    //The Laser Logic
    private func spawnLaser(asset: String, xOffset: CGFloat) {
        let laser = SKSpriteNode(imageNamed: asset)
        laser.setScale(0.03)
        //Place based on xOffset
        laser.position = CGPoint(x: shipNode.position.x + xOffset, y: shipNode.position.y + shipNode.size.height / 2)
        //Laser is Rectangle anyways
        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size)
        //Laser Velocity
        laser.physicsBody?.velocity = CGVector(dx: 0, dy: 900)
        //Lasers is not affected by Gravity, so it does not Fall down
        laser.physicsBody?.affectedByGravity = false
        laser.physicsBody?.categoryBitMask = PhysicsCategory.laser
        //Looking for Contact with Enemies or Upgrades
        laser.physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.upgrade
        //Not Reacting on Collisions
        laser.physicsBody?.collisionBitMask = PhysicsCategory.none
        addChild(laser)
        //Remove Laser from Canvas after 2 Seconds (Off-Screen by then) to prevent Memory Leaks
        laser.run(.sequence([.wait(forDuration: 2.0), .removeFromParent()]))
    }

    // MARK: Enemies
    private func spawnEnemies(_ time: TimeInterval) {
        //Spawn Enemies once a Second
        guard time - lastEnemySpawn > 1.0 else { return }
        lastEnemySpawn = time

        //Choose a random Asteroid
        let asteroid = Asteroid.random(difficulty: difficulty())
        let node = SKSpriteNode(imageNamed: asteroid.asset)
        node.name = "enemy"
        node.setScale(asteroid.scale)
        
        //Different Dimensions since we have Different Asteroids
        let half = node.size.width / 2
        let minX = -size.width / 2 + half
        let maxX = size.width / 2 - half
        
        let left = minX + 15
        let right = maxX - 15
        
        let x: CGFloat
        if left <= right {
            x = .random(in: left...right)
        } else {
            x = 0
        }
        
        //Spawn at top of Screen with 15px right and left to not Spawn it partially Off-Screen
        node.position = CGPoint(x: x, y: size.height / 2 + node.size.height)
        //Asteroid Stats
        node.userData = ["hp": asteroid.health, "speed": asteroid.speed]
        //Radial Body since the Assets are round-ish
        node.physicsBody = SKPhysicsBody(circleOfRadius: half)
        //Not affected by Gravity
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        //Looking for Contact with Laser or Spaceship
        node.physicsBody?.contactTestBitMask = PhysicsCategory.laser | PhysicsCategory.spaceship
        //Not Reacting on Collisions
        node.physicsBody?.collisionBitMask = PhysicsCategory.none
        addChild(node)

        //Falling Animation
        let direction: CGFloat = Bool.random() ? 1 : -1
        let rotations = CGFloat.random(in: 0.5...1.0)
        let fallDuration = size.height / asteroid.speed
        node.run(.rotate(byAngle: direction * rotations * .pi * 2, duration: TimeInterval(fallDuration)))
    }

    //To Make it Look like the Ship Flies towards them
    private func moveEnemies(delta: TimeInterval) {
        //Get all SpriteKit Children with Name "enemy"
        enumerateChildNodes(withName: "enemy") { node, _ in
            if let speed = node.userData?["speed"] as? CGFloat {
                //Fall down
                node.position.y -= speed * CGFloat(delta)
            }
            //If Asteroid Slips through, Take Damage
            if node.position.y + node.frame.height / 2 < -self.size.height / 2 {
                self.ship.health -= 1
                //Prevent Memory Leaks
                node.removeFromParent()
                //Game over
                if self.ship.health <= 0 { self.gameOver() }
            }
        }
    }

    // MARK: Upgrades
    //Probability Distribution of the Upgrades
    private let upgradeWeights: [(type: UpgradeType, weight: Double)] = [
        (.rapidFire, 0.55), (.overdrive, 0.3), (.health, 0.10), (.dualShot, 0.05)
    ]

    private func chooseRandomUpgrade() -> UpgradeType {
        let roll = Double.random(in: 0...1)
        var cumulative = 0.0
        //Store Weights for dynamic Filtering
        var filteredUpgrades = upgradeWeights
        
        //Dont Get dualshot twice since its a persistent Upgrade
        if ship.hasDualShot {
            filteredUpgrades.removeLast()
        }
        
        //For Simplicity with the Design
        if ship.health == 3 {
            filteredUpgrades.remove(at: 2)
        }
        
        // return the first upgrade weight that cumulatively added up (is that a word?) is smaller than the roll
        for entry in filteredUpgrades {
            cumulative += entry.weight
            if roll <= cumulative { return entry.type }
        }
        //Default if something Fails
        return .rapidFire
    }
    
    func spawnUpgrades(_ time: TimeInterval) {
        // Timing for Upgrade Spawns is Managed in Update
        
        let type = chooseRandomUpgrade()
        let node = SKSpriteNode(imageNamed: "spacestation")
        node.size = CGSize(width: 80, height: 80)
        node.name = "upgrade"
        //Upgrade Stats
        node.userData = ["type": type, "speed": CGFloat(80)]
        //Spawn at the top
        node.position = CGPoint(x: 0, y: size.height / 2 + node.size.height)
        // Hitbox
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        //Same as Enemies
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.upgrade
        //Looking for Contact with Laser
        node.physicsBody?.contactTestBitMask = PhysicsCategory.laser
        //Not Reacting to Collisions
        node.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        // Add the glowing Circle to Upgrades
        let glow = createUpgradeGlowCircle(radius: 40)
        node.addChild(glow)
        
        addChild(node)
    }
    
    private func printUpgradesToScreen() {
        //Clear previous Message
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
        //Append Message
        hudLines.append(line)
    }

    //Same as move Enemies
    private func moveUpgrades(delta: TimeInterval) {
        enumerateChildNodes(withName: "upgrade") { node, _ in
            if let speed = node.userData?["speed"] as? CGFloat {
                node.position.y -= speed * CGFloat(delta)
            }
            if node.position.y < -self.size.height / 2 - node.frame.height { node.removeFromParent() }
        }
    }

    // MARK: Collisions
    //This Cets Called when Contact Happens between 2 Parties, e.g. Laser and Enemy
    //Contact Stores both Parties
    func didBegin(_ contact: SKPhysicsContact) {
        //Which Parties caused the Contact
        guard let a = contact.bodyA.node, let b = contact.bodyB.node else { return }
        //Is one of them an Enemy
        let enemy = a.name == "enemy" ? a : b.name == "enemy" ? b : nil
        //Is one of them an Upgrade
        let upgrade = a.name == "upgrade" ? a : b.name == "upgrade" ? b : nil
        //Lasers Dont Have a Name, thats why we Check by Category
        let laser = contact.bodyA.categoryBitMask == PhysicsCategory.laser ? a : contact.bodyB.categoryBitMask == PhysicsCategory.laser ? b : nil
        //Spaceship Does not Have a Name, so we Check for Category
        let spaceship = contact.bodyA.categoryBitMask == PhysicsCategory.spaceship ? a : contact.bodyB.categoryBitMask == PhysicsCategory.spaceship ? b : nil
        //If theres an Enemy Involved
        if let enemy = enemy {
            //And a Spaceship
            if let spaceship = spaceship {
                //Take Damage
                ship.health -= 1
                //Damage Animation
                flashWhite(spaceship)
                //Damage Sound Effect
                playSFX("damage.wav", volume: 0.4)
                //Prevent Memory Leaks
                enemy.removeFromParent()
                //Check for Game over
                if ship.health <= 0 { self.gameOver() }
                return
            }
            //Since Enemy only Checks for Contact with either Spaceship or Asteroid, if it isnt the Spaceship it must be an Asteroid, so we Play one of three Hit Sound Effects
            playSFX("hit\(Int.random(in: 1...3)).wav", volume: 0.3)
            //Damage Animation
            flashWhite(enemy)
            // Deprecated, Asteroids could Have more HP, but we Opted more towards speedier Asteroids instead for increased Difficulty. Still nice to Have for the Future
            if let hp = enemy.userData?["hp"] as? Int, hp > 1 {
                enemy.userData?["hp"] = hp - 1
            } else {
                //Prevent Memory Leaks and Destroy Asteroid
                enemy.removeFromParent()
                //Give Score
                viewModel?.updateScore(points: 10)
            }
        }

        //If an Upgrade is Involved
        if let upgrade = upgrade, let type = upgrade.userData?["type"] as? UpgradeType {
            // if its the non-persistent one
            if type == .overdrive {
                //Override upgradeText
                upgradeText = "Overdrive Active"
                removeUpgradeText()
                //Activate the Upgrade
                activateOverdrive()
            } else {
                //Normal Upgrade
                ship.apply(type)
                if type == .rapidFire {
                    upgradeText = "Firerate Increased"
                } else {
                    upgradeText = "\(type) Gained"
                }
                removeUpgradeText()
            }
            //Destroy Upgrade
            upgrade.removeFromParent()
            //Give Score
            viewModel?.updateScore(points: 100)
        }
        //Prevent Memory Leaks
        if let laser = laser { laser.removeFromParent() }
    }
    
    private func removeUpgradeText() {
        //Clear upGradeText after 2 Seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.upgradeText = ""
        }
    }

    //Activate non-persistent Upgrade
    private func activateOverdrive() {
        //If the Upgrade Runs out of Time
        if overdriveRemaining > 0 {
            //Increase Duration every Time Upgrade is Collected
            overdriveRemaining += overdriveBonusDuration
        } else {
            //Save current Firerate to Get back to later
            preOverdriveFireRate = ship.fireRate
            //First Time Duration is Base Duration
            overdriveRemaining = overdriveBaseDuration
            //As fast as it Gets
            ship.fireRate = minFireRate
        }
        //Show overdrive Timer Overlay
        overdriveBackground.isHidden = false
    }

    //Non-persistent Upgrade Lifecycle
    private func updateOverdrive(delta: TimeInterval) {
        //Check Timer
        guard overdriveRemaining > 0 else { return }
        //Substract passed Time
        overdriveRemaining -= delta
        //Percentage for Timer UI
        let progress = max(0, overdriveRemaining) / overdriveBaseDuration
        overdriveFill.xScale = CGFloat(progress)
        if overdriveRemaining <= 0 {
            overdriveRemaining = 0
            //Hide Overlay if Timer is 0
            overdriveBackground.isHidden = true
            //Restore Firerate to previously saved Number
            if let previous = preOverdriveFireRate {
                ship.fireRate = previous
                preOverdriveFireRate = nil
            }
        }
    }

    //Damage Animation
    private func flashWhite(_ node: SKNode) {
        node.run(.sequence([
            //Short white Pulse
            .colorize(with: .white, colorBlendFactor: 1, duration: 0.05),
            .colorize(withColorBlendFactor: 0, duration: 0.05)
        ]))
    }
    
    //Non-persistent Upgrade Timer
    private func layoutOverdriveUI() {
        overdriveBackground.position = CGPoint(x: frame.midX, y: frame.height - frame.height * 1.3)
    }
    
    // MARK: - Play Audio
    private func playBackgroundMusic() {
        //Split Background Music into Intro and Looping Part so that the Intro is not Played twice
        guard !didPlayIntro else { return }

        //Get the Intro
        guard let url = Bundle.main.url(
            forResource: "backgroundMusicStart",
            withExtension: "wav"
        ) else {
            print("Intro file not found")
            return
        }
        
        //Play Music once
        do {
            backgroundMusic = try AVAudioPlayer(contentsOf: url)
            backgroundMusic?.delegate = self
            backgroundMusic?.numberOfLoops = 0
            backgroundMusic?.volume = 0.5
            backgroundMusic?.prepareToPlay()
            backgroundMusic?.play()
            //Intro Played
            didPlayIntro = true
        } catch {
            print("Failed to play intro music")
        }
    }
    
    //Play the looping Part of the Music
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
            //Loop indefinetely
            backgroundMusic?.numberOfLoops = -1
            backgroundMusic?.prepareToPlay()
            backgroundMusic?.play()
        } catch {
            print("Failed to play looping music")
        }
    }
    
    //Delegate Callback that Gets Called when the Audio Player finished Playing -> Causes looping
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playLoopingMusic()
    }
    
    // MARK: Sound Effects
    private func playSFX(_ file: String, volume: Float = 1.0) {
        if soundeffectsEnabled {
            //Using SKAction.playSoundFileNamed for short, one-shot Sound Effects since Audio adds a lot of Overhead for many short Sounds
            let playAction = SKAction.playSoundFileNamed(file, waitForCompletion: false)
            run(playAction)
        }
    }

    // MARK: Game Over
    private func gameOver() {
        ship.health = 0
        viewModel?.setGameOver()
        backgroundMusic?.stop()
        //Game over Sound Effect
        playSFX("gameover.mp3", volume: backgroundMusic!.volume)
        //Stop Game
        physicsWorld.speed = 0
        
        // Submit Score asynchronously
        Task {
            await submitScore()
        }
    }
    
    //Submit final Score of Player to the Backend
    private func submitScore() async {
        guard let vm = viewModel else { return }

        let scoreEntry = ScoreEntry(
            playerName: Player.shared.name,
            arenaId: vm.arenaId,
            arenaName: vm.arenaName,
            score: vm.scoreValue,
            maxDifficulty: Int(vm.maxDifficulty),
            createdAt: ISO8601DateFormatter().string(from: Date())
        )

        do {
            let service = BackendService()
            try await service.submitScore(score: scoreEntry)
            print("Score submitted successfully")
        } catch {
            print("Failed to submit score:", error)
        }
    }
    
    //MARK: Game Paused
    func gamePause() {
        //Stop everything, but Needs to be able to continue later and Set Flags
        recoverSpeed = physicsWorld.speed
        viewModel?.setGamePause()
        physicsWorld.speed = 0
        backgroundMusic?.stop()
    }
    
    func gameUnpause() {
        //Continue everything, which stopped before and Set Flags
        viewModel?.setGameUnpause()
        physicsWorld.speed = recoverSpeed
        backgroundMusic?.play()
    }

    // MARK: Input
    func beginDrag() {
        //Only move on the x Axis
        dragStartX = shipNode.position.x
    }
    
    func dragShip(by deltaX: CGFloat) {
        let proposedX = dragStartX + deltaX
        let half = shipNode.size.width / 2
        //Avoid Clamping
        shipNode.position.x = min(max(proposedX, -size.width / 2 + half), size.width / 2 - half)
    }

    //When Restarting the Game, Set everything back to the initial Values
    func reset() {
        ship = Spaceship()
        elapsed = 0
        lastFire = 0
        lastUpdateTime = 0
        lastEnemySpawn = 0
        lastUpgradeDrop = 0
        nextUpgradeDelay = Double.random(in: 13...16)
        //Clear absolute Upgrade Spawn Schedule; will be re-initialized on first Update Tick
        nextUpgradeSpawnAt = nil
        shootLeftNext = true
        overdriveRemaining = 0
        preOverdriveFireRate = nil
        physicsWorld.speed = 1.0
        didPlayIntro = false
        playBackgroundMusic()
        shipNode.position = CGPoint(x: 0, y: -size.height * 0.4)
        enumerateChildNodes(withName: "*") { node, _ in
            if let cat = node.physicsBody?.categoryBitMask, [PhysicsCategory.laser, PhysicsCategory.enemy, PhysicsCategory.upgrade].contains(cat) {
                node.removeFromParent()
            }
        }
        overdriveBackground.isHidden = true
        layoutScoreLabels()
        layoutOverdriveUI()
        layoutBackground()
    }
}

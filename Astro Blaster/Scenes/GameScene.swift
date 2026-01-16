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
    
    // MARK: Assets
    private let shipNode = SKSpriteNode(imageNamed: "spaceship")
    private var ship = Spaceship()
    private let health1 = SKSpriteNode(imageNamed: "heart")
    private let health2 = SKSpriteNode(imageNamed: "heart")
    private let health3 = SKSpriteNode(imageNamed: "heart")

    // MARK: State
    private var upgradeText = ""
    private var dragStartX: CGFloat = 0
    private var lastFire: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private var lastEnemySpawn: TimeInterval = 0
    private var lastUpgradeDrop: TimeInterval = 0
    private var nextUpgradeDelay: TimeInterval = Double.random(in: 13...16)
    private var shootLeftNext = true
    /// Absolute time when the next upgrade should spawn (scheduled relative to the first update tick)
    private var nextUpgradeSpawnAt: TimeInterval?
    
    // MARK: Active Upgrades
    private var overdriveRemaining: TimeInterval = 0
    private var overdriveBaseDuration: TimeInterval = 5.0
    private let overdriveBonusDuration: TimeInterval = 2.0
    private let minFireRate: TimeInterval = 0.12
    private var preOverdriveFireRate: TimeInterval?
    private let overdriveBackground = SKShapeNode(rectOf: CGSize(width: 120, height: 10), cornerRadius: 4)
    private let overdriveFill = SKShapeNode(rectOf: CGSize(width: 116, height: 6), cornerRadius: 3)
    
    // MARK: Background
    // spread into 3 since the original pic is 10000px in height and SK only supports up to 4096px
    private let background1 = SKSpriteNode(imageNamed: "backgroundTop")
    private let background2 = SKSpriteNode(imageNamed: "backgroundMid")
    private let background3 = SKSpriteNode(imageNamed: "backgroundBottom")
    // since the bottom one with the earth shouldnt reappear
    private var loopingBackgrounds: [SKSpriteNode] {
        [background1, background2]
    }


    // MARK: HUD & Score Labels
    private let hud = SKLabelNode(fontNamed: "ArcadeInterlaced")
    private var scoreLabel = SKLabelNode(fontNamed: "ArcadeInterlaced")
    private var highscoreLabel = SKLabelNode(fontNamed: "ArcadeInterlaced")
    private var hudLines: [SKLabelNode] = []
    private var hearts: [SKSpriteNode] = []

    // MARK: Lifecycle
    
    // gets called when the scene gets created
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self // for detecting collisions
        
        // needs to be done only once
        playBackgroundMusic()
        setupShip()
        setupHUD() // debugging
        setupOverdriveUI()
        setupScore()
        setupHearts()
        layoutOverdriveUI()
        setupBackground()
    }
    
    // consistency when scene size changes
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutScoreLabels()
    }

    // MARK: Setup functions
    private func setupShip() {
        shipNode.setScale(0.066)
        shipNode.zRotation = .pi // asset is the wrong way around
        shipNode.position = CGPoint(x: 0, y: -size.height * 0.4)
        shipNode.physicsBody = SKPhysicsBody(rectangleOf: shipNode.size) // set hitbox to rectangle of own size
        shipNode.physicsBody?.affectedByGravity = false // spaceships dont fall down
        shipNode.physicsBody?.categoryBitMask = PhysicsCategory.spaceship // im a spaceship
        shipNode.physicsBody?.contactTestBitMask = PhysicsCategory.enemy // im looking for contact with enemies
        shipNode.physicsBody?.collisionBitMask = PhysicsCategory.none // dont care for collisions

        // add to scene
        addChild(shipNode)
        
        // create contrail animation
        let leftEmitter = createContrail(at: -shipNode.size.width * 0.25)
        shipNode.addChild(leftEmitter)
        let rightEmitter = createContrail(at: shipNode.size.width * 0.25)
        shipNode.addChild(rightEmitter)
    }

    // particle shenanigans
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
    
    // glow circle around the upgrade
    func createUpgradeGlowCircle(radius: CGFloat = 50) -> SKShapeNode {
        let glow = SKShapeNode(circleOfRadius: radius) // circle
        glow.strokeColor = .yellow
        glow.lineWidth = 4
        glow.fillColor = .clear // inside transparent
        glow.alpha = 0.6
        glow.zPosition = -1  // behind the upgrade
        glow.glowWidth = 10

        // Pulsate animation
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.8)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.8)
        let pulse = SKAction.repeatForever(.sequence([scaleUp, scaleDown]))
        glow.run(pulse) // run the animation on the glow node
        
        return glow
    }
    
    // how fast does the background scroll
    private var backgroundScrollSpeed: CGFloat {
        guard let vm = viewModel, !vm.isGameOver else { return 0 } // only if viemodel is connected and not game over
        return 40 + difficulty() * 20   // scales with difficulty
    }
    
    // well its scrolls the background
    private func scrollBackground(delta: TimeInterval) {
        let move = backgroundScrollSpeed * CGFloat(delta)

        // Move all backgrounds
        [background1, background2, background3].forEach {
            $0.position.y -= move
        }

        // Recycle only looping backgrounds
        for bg in loopingBackgrounds {

            // Fully below the screen?
            if bg.position.y + bg.size.height / 2 < -size.height / 2 {

                // Find the current top-most looping background
                let topMostY = loopingBackgrounds
                    .map { $0.position.y + $0.size.height / 2 }
                    .max() ?? 0

                // Place this background above it
                bg.position.y = topMostY + bg.size.height / 2
            }
        }
    }
    
    private func setupBackground() {

        // different sizes since we had to crop it and im no surgeon
        let h1 = background1.size.height
        let h2 = background2.size.height
        let h3 = background3.size.height

        // Place bottom image so it is visible at boot
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

        // move to background
        background1.zPosition = -200
        background2.zPosition = -200
        background3.zPosition = -200

        addChild(background1)
        addChild(background2)
        addChild(background3)
    }

    // debugging
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

    // UI Timer for non-persistent upgrade
    private func setupOverdriveUI() {
        overdriveBackground.fillColor = .white
        overdriveBackground.strokeColor = .clear
        overdriveBackground.zPosition = 300
        overdriveBackground.isHidden = true
        overdriveFill.fillColor = .green
        overdriveFill.strokeColor = .clear
        overdriveFill.zPosition = 301 // foremostground (is that even a word?)
        overdriveBackground.addChild(overdriveFill)
        addChild(overdriveBackground)
    }

    // score and highscore
    private func layoutScoreLabels() {
        scoreLabel.position = CGPoint(x: size.width / 8 - 200, y: size.height / 2 - 70)
        highscoreLabel.position = CGPoint(x: scoreLabel.position.x, y: scoreLabel.position.y - 20)
    }
    
    private func layoutHearts() {
        // Position relative to score label
        let startX = scoreLabel.position.x + health1.size.width / 2
        let y = scoreLabel.position.y - 40
        for (i, heart) in hearts.enumerated() {
            heart.position = CGPoint(x: startX + CGFloat(i) * 20, y: y)
        }
    }

    // MARK: Game Scale
    
    // game scaling difficulty over time
    private func difficulty() -> CGFloat {
        let t = CGFloat(elapsed)
        let maxDifficulty = viewModel?.maxDifficulty ?? 5.0 // passed by viewmodel
        let value = maxDifficulty * (1 - exp(-t / difficultyTimeConstant)) // plateaus at maxDifficulty
        return min(value, maxDifficulty) // only up to maxDifficulty
    }

    // MARK: - Update
    
    // gets called once per frame
    override func update(_ currentTime: TimeInterval) {
        guard let vm = viewModel, !vm.isGameOver else { return } // check for viewmodel and if not game over
        
        let delta = computeDeltaTime(currentTime: currentTime) // account for different frame rates
        elapsed += delta // counts elapsed time to keep track of how long its been played

        // Schedule the first upgrade spawn relative to the first scene tick to avoid immediate spawn due to large absolute currentTime
        if nextUpgradeSpawnAt == nil {
            nextUpgradeSpawnAt = currentTime + Double.random(in: 13...16)
        }

        vm.updateScore(points: 1) // Passive score over time
        scoreLabel.text = "Score: \(vm.scoreValue)"
        highscoreLabel.text = "High: \(vm.highscore)"

        // updating the game state
        fireLasers(currentTime)
        spawnEnemies(currentTime)
        
        // Spawn an upgrade only when the absolute clock reaches the scheduled time
        if let scheduled = nextUpgradeSpawnAt, currentTime >= scheduled {
            spawnUpgrades(currentTime)
            // Reschedule the next upgrade spawn relative to the current time
            nextUpgradeSpawnAt = currentTime + Double.random(in: 13...16)
        }
        
        moveEnemies(delta: delta)
        moveUpgrades(delta: delta)
        updateHUD()
        updateHealth()
        printUpgradesToScreen()
        updateOverdrive(delta: delta) // non-persistent upgrade
        layoutOverdriveUI()
        scrollBackground(delta: delta)
    }

    // account for different framerates
    private func computeDeltaTime(currentTime: TimeInterval) -> TimeInterval {
        let delta = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 1.0 / 60.0 // since lastUpdateTime is initialized with zero, we need to update it at least once with a default fps value since the delta would otherwise be negativew which adds too many difficulties
        lastUpdateTime = currentTime // for next comparison
        return delta
    }
    
    // toggles visibility of hearts based on ships health
    private func updateHealth() {
        for (index, heart) in hearts.enumerated() {
            heart.isHidden = index >= ship.health
        }
    }

    // MARK: Lasers
    private func fireLasers(_ time: TimeInterval) {
        guard time - lastFire >= ship.fireRate else { return } // only fire after "fireRate" amount of time has passed
        lastFire = time

        // if dualshot upgrade is unlocked shoot both lasers at the same time
        if ship.hasDualShot {
            spawnLaser(asset: "BlasterschussLinks", xOffset: -12)
            spawnLaser(asset: "BlasterschussRechts", xOffset: 12)
        } else {
            let asset = shootLeftNext ? "BlasterschussLinks" : "BlasterschussRechts" // alternating fire based on shootLeftNext flag
            spawnLaser(asset: asset, xOffset: shootLeftNext ? -30 : 30)
            shootLeftNext.toggle()
        }
        playSFX("laser.wav", volume: 0.2) // laser sound effect
    }

    // the laser logic (that sounds fire)
    private func spawnLaser(asset: String, xOffset: CGFloat) {
        let laser = SKSpriteNode(imageNamed: asset)
        laser.setScale(0.03)
        laser.position = CGPoint(x: shipNode.position.x + xOffset, y: shipNode.position.y + shipNode.size.height / 2) // place based on xOffset
        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size) // laser is rectangle anyways
        laser.physicsBody?.velocity = CGVector(dx: 0, dy: 900) // how fast
        laser.physicsBody?.affectedByGravity = false // lasers dont fall
        laser.physicsBody?.categoryBitMask = PhysicsCategory.laser // im a laser
        laser.physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.upgrade // looking for contact with enemies or upgrades
        laser.physicsBody?.collisionBitMask = PhysicsCategory.none // not reacting on collisions
        addChild(laser)
        laser.run(.sequence([.wait(forDuration: 2.0), .removeFromParent()])) // remove laser from canvas after 2 seconds (off-screen by then) to prevent memory leaks
    }

    // MARK: Enemies
    private func spawnEnemies(_ time: TimeInterval) {
        guard time - lastEnemySpawn > 1.0 else { return } // spawn enemies once a second TODO: spawn enemies in random intervals
        lastEnemySpawn = time

        let asteroid = Asteroid.random(difficulty: difficulty()) // choose a random asteroid
        let node = SKSpriteNode(imageNamed: asteroid.asset)
        node.name = "enemy"
        node.setScale(asteroid.scale)
        
        // different dimensions since we have different asteroids
        let half = node.size.width / 2
        let minX = -size.width / 2 + half
        let maxX = size.width / 2 - half
        
        node.position = CGPoint(x: CGFloat.random(in: minX + 15 ... maxX - 15), y: size.height / 2 + node.size.height) // spawn at top of screen with 15px right and left to not spawn it partially off-screen
        node.userData = ["hp": asteroid.health, "speed": asteroid.speed] // asteroid stats
        node.physicsBody = SKPhysicsBody(circleOfRadius: half) // radial body since the assets are round-ish
        node.physicsBody?.affectedByGravity = false // were in space (im some sort of a scientist myself)
        node.physicsBody?.categoryBitMask = PhysicsCategory.enemy // im an enemy
        node.physicsBody?.contactTestBitMask = PhysicsCategory.laser | PhysicsCategory.spaceship // looking for contact with laser or spaceship
        node.physicsBody?.collisionBitMask = PhysicsCategory.none // not reacting on collisions
        addChild(node)

        // falling animation
        let direction: CGFloat = Bool.random() ? 1 : -1
        let rotations = CGFloat.random(in: 0.5...1.0)
        let fallDuration = size.height / asteroid.speed
        node.run(.rotate(byAngle: direction * rotations * .pi * 2, duration: TimeInterval(fallDuration)))
    }

    // to make it look like the ship flies towards them
    private func moveEnemies(delta: TimeInterval) {
        // get all SpriteKit children with name "enemy"
        enumerateChildNodes(withName: "enemy") { node, _ in
            if let speed = node.userData?["speed"] as? CGFloat {
                node.position.y -= speed * CGFloat(delta) // fall down
            }
            // if asteroid slips through, take damage
            if node.position.y + node.frame.height / 2 < -self.size.height / 2 {
                self.ship.health -= 1
                node.removeFromParent() // prevent memory leaks
                if self.ship.health <= 0 { self.gameOver() } // game over
            }
        }
    }

    // MARK: Upgrades
    // probability distribution of the upgrades
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
        
        // return the first upgrade weight that cumulatively added up (is that a word?) is smaller than the roll
        for entry in filteredUpgrades {
            cumulative += entry.weight
            if roll <= cumulative { return entry.type }
        }
        return .rapidFire // default if something fails
    }
    
    func spawnUpgrades(_ time: TimeInterval) {
        // Timing for upgrade spawns is managed in update
        
        let type = chooseRandomUpgrade()
        let node = SKSpriteNode(imageNamed: "spacestation")
        node.size = CGSize(width: 80, height: 80)
        node.name = "upgrade"
        node.userData = ["type": type, "speed": CGFloat(80)] // upgrade stats
        node.position = CGPoint(x: 0, y: size.height / 2 + node.size.height) // spawn at the top
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size) // hitbox
        node.physicsBody?.affectedByGravity = false // same as enemies
        node.physicsBody?.categoryBitMask = PhysicsCategory.upgrade // im an upgrade
        node.physicsBody?.contactTestBitMask = PhysicsCategory.laser // looking for contact with laser
        node.physicsBody?.collisionBitMask = PhysicsCategory.none // not reacting to collisions
        
        // Add the glowing circle
        let glow = createUpgradeGlowCircle(radius: 40)
        node.addChild(glow)
        
        addChild(node)
    }
    
    private func printUpgradesToScreen() {
        hudLines.forEach { $0.removeFromParent() } // clear previous message
        hudLines.removeAll()
        let line = SKLabelNode(fontNamed: "ArcadeInterlaced") // custom font
        line.text = upgradeText
        line.fontColor = .green
        line.fontSize = 12
        line.horizontalAlignmentMode = .center
        line.position.x = 0
        line.position.y = -(frame.height/4 + 25)
        line.zPosition = 100 // foreground
        addChild(line)
        hudLines.append(line) // append message
    }

    // same as move enemies
    private func moveUpgrades(delta: TimeInterval) {
        enumerateChildNodes(withName: "upgrade") { node, _ in
            if let speed = node.userData?["speed"] as? CGFloat {
                node.position.y -= speed * CGFloat(delta)
            }
            if node.position.y < -self.size.height / 2 - node.frame.height { node.removeFromParent() }
        }
    }

    // MARK: Collisions
    // this gets called when contact happens between 2 parties, e.g. laser and enemy
    func didBegin(_ contact: SKPhysicsContact) { // contact stores both parties
        // which parties caused the contact
        guard let a = contact.bodyA.node, let b = contact.bodyB.node else { return }
        let enemy = a.name == "enemy" ? a : b.name == "enemy" ? b : nil // is one of them an enemy
        let upgrade = a.name == "upgrade" ? a : b.name == "upgrade" ? b : nil // is one of them an upgrade
        let laser = contact.bodyA.categoryBitMask == PhysicsCategory.laser ? a : contact.bodyB.categoryBitMask == PhysicsCategory.laser ? b : nil // lasers dont have a name, thats why we check by category
        let spaceship = contact.bodyA.categoryBitMask == PhysicsCategory.spaceship ? a : contact.bodyB.categoryBitMask == PhysicsCategory.spaceship ? b : nil // spaceship does not have a name, so we check for category

        if let enemy = enemy { // if theres an enemy involved
            if let spaceship = spaceship { // and a spaceship
                ship.health -= 1 // take damage
                flashWhite(spaceship) // damage animation
                playSFX("damage.wav", volume: 0.4) // damage sound effect
                enemy.removeFromParent() // prevent memory leaks
                if ship.health <= 0 { self.gameOver() } // check for game over
                return
            }
            playSFX("hit\(Int.random(in: 1...3)).wav", volume: 0.3) // since enemy only checks for contact with either spaceship or asteroid, if it isnt the spaceship it must be an asteroid, so we play one of three hit sound effects
            flashWhite(enemy) // damage animation
            if let hp = enemy.userData?["hp"] as? Int, hp > 1 { // deprecated, asteroids could have more hp but we opted more towards speedier asteroids instead for increased difficulty. Still nice to have for the future
                enemy.userData?["hp"] = hp - 1
            } else {
                enemy.removeFromParent() // prevent memory leaks and destroy asteroid
                viewModel?.updateScore(points: 10) // give credit
            }
        }

        if let upgrade = upgrade, let type = upgrade.userData?["type"] as? UpgradeType { // if an upgrade is involved
            if type == .overdrive { // if its the non-persistent one
                upgradeText = "Overdrive Active" // display the text
                removeUpgradeText()
                activateOverdrive() // activate the upgrade
            } else {
                ship.apply(type) // normal upgrade
                upgradeText = "\(type) Gained"
                removeUpgradeText()
            }
            upgrade.removeFromParent() // destroy upgrade
            viewModel?.updateScore(points: 100) // give credit
        }
        
        if let laser = laser { laser.removeFromParent() } // prevent memory leaks
    }
    
    private func removeUpgradeText() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.upgradeText = "" // clear variable after short time for future uses
        }
    }

    // activate non-persistent upgradae
    private func activateOverdrive() {
        if overdriveRemaining > 0 { // only until it runs out
            overdriveRemaining += overdriveBonusDuration // increase time every time you get it
        } else {
            preOverdriveFireRate = ship.fireRate // save for later restoration
            overdriveRemaining = overdriveBaseDuration // first time gets base duration
            ship.fireRate = minFireRate // as fast as it gets
        }
        overdriveBackground.isHidden = false // show timer overlay
    }

    // non-persistent upgrade lifecycle
    private func updateOverdrive(delta: TimeInterval) {
        guard overdriveRemaining > 0 else { return } // check timer
        overdriveRemaining -= delta // subtract passed time
        let progress = max(0, overdriveRemaining) / overdriveBaseDuration // percentage for timer ui
        overdriveFill.xScale = CGFloat(progress)
        if overdriveRemaining <= 0 {
            overdriveRemaining = 0
            overdriveBackground.isHidden = true // hide overlay when timer is done
            if let previous = preOverdriveFireRate { // restore firerate
                ship.fireRate = previous
                preOverdriveFireRate = nil
            }
        }
    }

    // damage animation
    private func flashWhite(_ node: SKNode) {
        node.run(.sequence([
            .colorize(with: .white, colorBlendFactor: 1, duration: 0.05), // short white pulse
            .colorize(withColorBlendFactor: 0, duration: 0.05)
        ]))
    }

    // deprecated, here for eventualities
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

    // non-persistent upgrade timer
    private func layoutOverdriveUI() {
        overdriveBackground.position = CGPoint(x: frame.midX, y: frame.height - frame.height * 1.3)
    }
    
    // MARK: - Play Audio
    private func playBackgroundMusic() {
        guard !didPlayIntro else { return } // for looping we split the music in two parts, the intro and the looping part

        // get the intro
        guard let url = Bundle.main.url(
            forResource: "backgroundMusicStart",
            withExtension: "wav"
        ) else {
            print("Intro file not found")
            return
        }
        
        // play the music once
        do {
            backgroundMusic = try AVAudioPlayer(contentsOf: url)
            backgroundMusic?.delegate = self // append delegate
            backgroundMusic?.numberOfLoops = 0
            backgroundMusic?.prepareToPlay()
            backgroundMusic?.play()
            didPlayIntro = true // intro played
        } catch {
            print("Failed to play intro music")
        }
    }
    
    // play the looping part of the music
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
            backgroundMusic?.numberOfLoops = -1 // loop infinetly
            backgroundMusic?.prepareToPlay()
            backgroundMusic?.play()
        } catch {
            print("Failed to play looping music")
        }
    }
    
    // delegate callback that gets called when the audio player finished playing -> causes looping
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playLoopingMusic()
    }
    
    // MARK: Sound Effects
    private func playSFX(_ file: String, volume: Float = 1.0) {
        // Using SKAction.playSoundFileNamed for short, one-shot sound effects since audio adds a lot of overhead for many short sounds
        let playAction = SKAction.playSoundFileNamed(file, waitForCompletion: false)
        run(playAction)
    }

    // MARK: Game Over
    private func gameOver() {
        ship.health = 0
        viewModel?.setGameOver()
        backgroundMusic?.stop()
        playSFX("gameover.mp3", volume: 0.6) // game over sound effect
        physicsWorld.speed = 0 // stop the game
    }

    // MARK: Input
    func beginDrag() {
        dragStartX = shipNode.position.x // only move on the x axis
    }
    
    func dragShip(by deltaX: CGFloat) {
        let proposedX = dragStartX + deltaX
        let half = shipNode.size.width / 2
        shipNode.position.x = min(max(proposedX, -size.width / 2 + half), size.width / 2 - half) // avoid clamping
    }

    // when restarting the game, set everything back to the initial values
    func reset() {
        ship = Spaceship()
        elapsed = 0
        lastFire = 0
        lastUpdateTime = 0
        lastEnemySpawn = 0
        lastUpgradeDrop = 0
        nextUpgradeDelay = Double.random(in: 13...16)
        // Clear absolute upgrade spawn schedule; it will be re-initialized on first update tick
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
    }
}


//
//  Player.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 20.01.26.
//

import Foundation

struct Player {
    var name: String
    
    // shared singleton for access across the whole app
    static var shared = Player.load()
    
    // MARK: - Load or create a player
    private static func load() -> Player {
        if let savedName = UserDefaults.standard.string(forKey: "playerName") { // persistent name
            return Player(name: savedName)
        } else {
            let randomName = generateRandomName() // if no name has been specified, generate a random one since we need one for linking the score to the player
            UserDefaults.standard.set(randomName, forKey: "playerName")
            return Player(name: randomName)
        }
    }
    
    // MARK: - Save changes
    func save() {
        UserDefaults.standard.set(name, forKey: "playerName")
    }
    
    // MARK: - Random funny name generator
    private static func generateRandomName() -> String {
        let adjectives = ["Crazy", "Sneaky", "Flying", "Turbo", "Mega", "Astro", "Pixel", "Cosmic"]
        let nouns = ["Blaster", "Laser", "Rocket", "Alien", "Star", "Meteor", "Photon", "Plasma"]
        
        let adjective = adjectives.randomElement()!
        let noun = nouns.randomElement()!
        let number = Int.random(in: 1...99)
        
        return "\(adjective)\(noun)\(number)"
    }
}

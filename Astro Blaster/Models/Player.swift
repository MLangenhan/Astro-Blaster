//
//  Player.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 20.01.26.
//

import Foundation

struct Player {
    var name: String
    
    //Shared Singleton for Access across the whole App
    static var shared = Player.load()
    
    //Load or Create a Player
    private static func load() -> Player {
        if let savedName = UserDefaults.standard.string(forKey: "playerName") { // persistent name
            return Player(name: savedName)
        } else {
            //If no Name has been specified, Generate a random one since we need one for Linking the Score to the Player
            let randomName = generateRandomName()
            UserDefaults.standard.set(randomName, forKey: "playerName")
            return Player(name: randomName)
        }
    }
    
    //Save Name Change
    func save() {
        UserDefaults.standard.set(name, forKey: "playerName")
    }
    
    //Random Name generator
    private static func generateRandomName() -> String {
        let adjectives = ["Crazy", "Sneaky", "Flying", "Turbo", "Mega", "Astro", "Pixel", "Cosmic"]
        let nouns = ["Blaster", "Laser", "Rocket", "Alien", "Star", "Meteor", "Photon", "Plasma"]
        
        let adjective = adjectives.randomElement()!
        let noun = nouns.randomElement()!
        let number = Int.random(in: 1...99)
        
        return "\(adjective)\(noun)\(number)"
    }
}

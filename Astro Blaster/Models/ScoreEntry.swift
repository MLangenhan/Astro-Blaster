//
//  Player.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 20.01.26.
//

import Foundation

//Backend Entry Format for each Game played
struct ScoreEntry: Codable {
    // MongoDB ID, may be nil for new Submissions
    var _id: String? = nil
    let playerName: String
    let arenaId: String
    let arenaName: String
    let score: Int
    let maxDifficulty: Int
    let createdAt: String

    var id: String {
        _id ?? "\(playerName)-\(arenaId)-\(score)-\(createdAt)"
    }
}


//
//  Player.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 20.01.26.
//

import Foundation

struct ScoreEntry: Codable {
    var _id: String? = nil        // MongoDB ID, may be nil for new submissions
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


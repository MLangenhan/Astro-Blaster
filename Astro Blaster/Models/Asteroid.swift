//
//  Asteroid.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 18.12.25.
//

import Foundation
import CoreGraphics

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

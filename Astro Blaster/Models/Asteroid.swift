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
            health: 1,
            speed: min(600, 60 + difficulty * 40),
            scale: CGFloat(Float.random(in: 0.025...0.05)),
            asset: "asteroid\(Int.random(in: 1...7))"
        )
    }
}

//
//  Spaceship.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 18.12.25.
//

import Foundation

// MARK: - Spaceship Model

struct Spaceship {
    var fireRate: TimeInterval = 0.8 // in seconds
    var health: Int = 3
    var hasDualShot: Bool = false

    // update stats according to collected upgrade
    mutating func apply(_ upgrade: UpgradeType) {
        switch upgrade {
        case .health:
            health += 1
        case .rapidFire:
            fireRate = max(0.12, fireRate - 0.04)
        case .dualShot:
            hasDualShot = true
        case .overdrive:
            break
        }
    }
}

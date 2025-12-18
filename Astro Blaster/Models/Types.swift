//
//  Types.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 18.12.25.
//

import Foundation

enum UpgradeType: CaseIterable {
    case health
    case rapidFire
    case dualShot
    case overdrive
}

struct PhysicsCategory {
    static let none: UInt32      = 0
    static let spaceship: UInt32 = 1 << 0
    static let laser: UInt32     = 1 << 1
    static let enemy: UInt32     = 1 << 2
    static let upgrade: UInt32   = 1 << 3
}

enum GameAction {
    case restart
    case exitToMap
}

//
//  Astro_BlasterApp.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 09.12.25.
//

import SwiftUI
import GameKit

@main
struct Astro_BlasterApp: App {

    init() {
        authenticateGameCenter()
    }

    var body: some Scene {
        WindowGroup {
            MapView()
        }
    }

    private func authenticateGameCenter() {
        let player = GKLocalPlayer.local
        player.authenticateHandler = { vc, error in
            if let vc = vc {
                // Present login UI using the root controller
                UIApplication.shared.connectedScenes
                    .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                    .first?
                    .rootViewController?
                    .present(vc, animated: true)
            } else if player.isAuthenticated {
                print("Game Center authenticated: \(player.alias)")
            } else {
                print("Game Center authentication failed: \(String(describing: error))")
            }
        }
    }
}

//
//  GameCenterLeaderboardView.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 19.01.26.
//

import Foundation
import SwiftUI
import GameKit

struct GameCenterLeaderboardView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc = GKGameCenterViewController()
        vc.gameCenterDelegate = context.coordinator
        vc.viewState = .leaderboards
        vc.leaderboardIdentifier = "lb1"
        return vc
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
        }
    }
}

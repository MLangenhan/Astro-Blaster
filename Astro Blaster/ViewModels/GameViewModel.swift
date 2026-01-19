//
//  GameViewModel.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 18.12.25.
//

import Foundation
import SwiftUI
import Combine
import GameKit

final class GameViewModel: ObservableObject {
    
    let arena: ArenaPlace
    
    // MARK: GameCenter Service
    struct GameCenterService {
        static func submit(score: Int, leaderboardID: String) {
            guard GKLocalPlayer.local.isAuthenticated else { return }
            let gkScore = GKScore(leaderboardIdentifier: leaderboardID)
            gkScore.value = Int64(score)
            GKScore.report([gkScore]) { error in
                if let error = error {
                    print("Score submission failed: \(error)")
                } else {
                    print("Score submitted: \(score) to \(leaderboardID)")
                }
            }
        }
    }
    
    // MARK: - Published State
    @Published var isGameOver = false
    @Published var isGamePaused = false
    @Published var scoreValue: Int = 0
    @Published var highscore: Int = 0
    
    // MARK: - Logic & Persistence
    private var highscoreKey: String { "Highscore_\(arena.leaderboardID)" }

    let maxDifficulty: CGFloat
    
    init(maxDifficulty: CGFloat, arena: ArenaPlace) {
        self.maxDifficulty = maxDifficulty
        self.arena = arena
        loadHighscore()
    }
    
    func loadHighscore() {
        highscore = UserDefaults.standard.integer(forKey: highscoreKey)
    }
    
    func saveHighscore() {
        UserDefaults.standard.set(highscore, forKey: highscoreKey)
    }
    
    func updateScore(points: Int) {
        scoreValue += points
        if scoreValue > highscore {
            highscore = scoreValue
            saveHighscore()
        }
    }
    
    func resetGame() {
        scoreValue = 0
        isGameOver = false
    }
    
    func setGameOver() {
        isGameOver = true
        GameCenterService.submit(score: scoreValue, leaderboardID: arena.leaderboardID)
    }
    
    func setGamePause() {
        isGamePaused = true
        
    }
    
    func setGameUnpause() {
        isGamePaused = false
    }
}

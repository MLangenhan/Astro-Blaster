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
    
    // MARK: GameCenter Service
    enum GameCenterService {
        static let leaderboardID = "lb1"

        static func submit(score: Int) {
            guard GKLocalPlayer.local.isAuthenticated else { return }

            let gkScore = GKScore(leaderboardIdentifier: leaderboardID)
            gkScore.value = Int64(score)

            GKScore.report([gkScore]) { error in
                if let error = error {
                    print("Score submission failed: \(error)")
                } else {
                    print("Score submitted: \(score)")
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
    private let highscoreKey = "Highscore"
    let maxDifficulty: CGFloat
    
    init(maxDifficulty: CGFloat) {
        self.maxDifficulty = maxDifficulty
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
        
        // Submit score to Game Center
        GameCenterService.submit(score: scoreValue)
    }
    
    func setGamePause() {
        isGamePaused = true
        
    }
    
    func setGameUnpause() {
        isGamePaused = false
    }
}

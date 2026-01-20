//
//  GameViewModel.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 18.12.25.
//

import Foundation
import SwiftUI
import Combine

final class GameViewModel: ObservableObject {

    // MARK: - Published State
    @Published var isGameOver = false
    @Published var isGamePaused = false
    @Published var scoreValue: Int = 0
    @Published var highscore: Int = 0
    
    // MARK: - Logic & Persistence
    private var highscoreKey: String = "Highscore"

    let maxDifficulty: CGFloat
    let arenaId: String
    let arenaName: String

    init(maxDifficulty: CGFloat,
         arenaId: String = "",
         arenaName: String = ""
    ) {
        self.maxDifficulty = maxDifficulty
        self.arenaId = arenaId
        self.arenaName = arenaName
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
    }
    
    func setGamePause() {
        isGamePaused = true
        
    }
    
    func setGameUnpause() {
        isGamePaused = false
    }
    
    func submitScore(arenaId: String, arenaName: String, score: Int, maxDifficulty: Int) async {
        let newScore = ScoreEntry(
            _id: nil,
            playerName: Player.shared.name,
            arenaId: arenaId,
            arenaName: arenaName,
            score: score,
            maxDifficulty: maxDifficulty,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            let service = BackendService()
            try await service.submitScore(score: newScore)
        } catch {
            print("Failed to submit score:", error)
        }
    }

}

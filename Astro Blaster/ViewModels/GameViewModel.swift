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
    }
    
    func setGamePause() {
        isGamePaused = true
        
    }
    
    func setGameUnpause() {
        isGamePaused = false
    }
}

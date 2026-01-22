//
//  SettingsPanel.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 19.01.26.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State var scores : [ScoreEntry] = []
    
    var body: some View {
        VStack {
            // Highscore-Header
            Text("Leaderboard")
                .font(.custom("ArcadeInterlaced", size: 28))
                .foregroundColor(.green)
                .padding(.bottom, 10)
                .padding(.top, 20)
            
            HighscoreView(scores: $scores)
            
            
        }
        .onAppear() {
            Task {
                do {
                    var seenPlayers : Set<String> = []
                    var filteredScores: [ScoreEntry] = []
                    let service = BackendService()
                    scores = try await service.fetchGlobalLeaderboard()
                    filteredScores = scores.filter {entry in
                        if seenPlayers.contains(entry.playerName){
                            return false
                        } else {
                            seenPlayers.insert(entry.playerName)
                            return true
                        }
                    }
                    scores = filteredScores
                } catch { print("failed fetching global leaderboard") }
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

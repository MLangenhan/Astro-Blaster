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
            Text("Global Leaderboard")
                .font(.custom("ArcadeInterlaced", size: 28))
                .foregroundColor(.green)
                .padding(.bottom, 10)
            
            HighscoreView(scores: $scores)
            
            
        }
        .onAppear() {
            Task {
                do {
                    let service = BackendService()
                    scores = try await service.fetchGlobalLeaderboard()
                }
                catch { print("failed fetching global leaderboard") }
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

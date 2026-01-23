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
            HStack {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.custom("ArcadeInterlaced", size: 14))
                        .foregroundColor(.green)
                }

                Spacer()
            }
            .padding()
            
            // Highscore-Header
            Text("Leaderboard")
                .font(.custom("ArcadeInterlaced", size: 28))
                .foregroundColor(.green)
                .padding(.bottom, 10)
            List {
                ForEach(Array(scores.enumerated()), id: \.offset) { index, entry in
                    HStack {
                        Text("#\(index + 1)")
                            .font(.custom("ArcadeInterlaced", size: 20))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(entry.playerName)
                            .font(.custom("ArcadeInterlaced", size: 12))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(entry.score) pts")
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.black)
                    .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .cornerRadius(12)
        }
        .background(Color.black.ignoresSafeArea())
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
    }
}

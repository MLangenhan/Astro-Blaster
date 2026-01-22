//
//  HighscoreView.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 11.01.26.
//

import SwiftUI
import CoreLocation

struct HighscoreView: View {
    
    @Binding var scores: [ScoreEntry]
    
//    private var sortedScores: [(key: String, value: Int)] {
//        scores.sorted { $0.value > $1.value }
//    }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            
            // Back-Button
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
            Text("Highscores")
                .font(.custom("ArcadeInterlaced", size: 28))
                .foregroundColor(.green)
                .padding(.bottom, 10)

            // Highscore List
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
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
}

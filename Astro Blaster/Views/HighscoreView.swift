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
                        //Position of the i-th Player, Counts from 0
                        Text("#\(index + 1)")
                            .font(.custom("ArcadeInterlaced", size: 20))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        //Name of the i-th Player
                        Text(entry.playerName)
                            .font(.custom("ArcadeInterlaced", size: 12))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        //All Time Highscore of i-th Player
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

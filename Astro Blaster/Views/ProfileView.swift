//
//  ProfileView.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 19.01.26.
//

import SwiftUI

struct ProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var playerName: String = Player.shared.name
    @State private var scores: [ScoreEntry] = []
    @State private var sumOfScores: Int = 0
    
    var body: some View {
        VStack {
            
            // Back Button
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
            
            // Header
            Text("Profile")
                .font(.custom("ArcadeInterlaced", size: 28))
                .foregroundColor(.green)
                .padding(.bottom, 10)
            
            Text(playerName)
                .font(.custom("ArcadeInterlaced", size: 20))
                .foregroundColor(.green)
                .padding(.bottom, 40)
            
            //Display of All-Time Total Score and All-Time Highscore
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("All-Time Score:")
                        .font(.custom("ArcadeInterlaced", size: 14))
                        .foregroundColor(.white)
                    
                    Text("\(sumOfScores)")
                        .font(.custom("ArcadeInterlaced", size: 14))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("All-Time High:")
                        .font(.custom("ArcadeInterlaced", size: 14))
                        .foregroundColor(.white)
                    if !scores.isEmpty {
                    Text(" \(scores[0].score)")
                            .font(.custom("ArcadeInterlaced", size: 14))
                            .foregroundColor(.white)
                    } else {
                        Text(" 0")
                            .font(.custom("ArcadeInterlaced", size: 14))
                            .foregroundColor(.white)
                    }
                }
                
                //Dividing Scores and Player Name Editor
                Divider()
                    .overlay(.white)
                    .frame(height:4)
                    .padding(.bottom,40)
                    .padding(.top,40)
            
            // Player Name Editor
                HStack {
                    Text("Name")
                        .font(.custom("ArcadeInterlaced", size: 14))
                        .foregroundColor(.white)
                    
                    TextField("Enter your name", text: $playerName)
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
                
            }
            .padding(.horizontal)
            
            // Save Button
            Button {
                Player.shared.name = playerName
                Player.shared.save()
            } label: {
                Text("Save")
                    .font(.custom("ArcadeInterlaced", size: 16))
                    .foregroundColor(.green)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green, lineWidth: 2)
                    )
            }
            .padding(.horizontal)
            
            Spacer()
            Spacer()
    
        }
        .onAppear() {
            Task {
                do {
                    //Backend Call to get all Highscores of a Player
                    let service = BackendService()
                    scores = try await service.getPersonalHighscores(playerId: playerName)
                    //Calculating every Score ever Achieved Totaled into One
                    sumOfScores = scores.reduce(0) { $0 + $1.score }
                }
                catch { print("failed fetching personal leaderboard") }
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

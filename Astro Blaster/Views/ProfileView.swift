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
            
            Spacer()
            
            // Player Name Editor
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Name")
                    .font(.custom("ArcadeInterlaced", size: 14))
                    .foregroundColor(.white)
                
                TextField("Enter your name", text: $playerName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.bottom, 10)
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
            
            HighscoreView(scores: $scores)
            
            Spacer()
        }
        .onAppear() {
            Task {
                do {
                    let service = BackendService()
                    scores = try await service.getPersonalHighscores(playerId: playerName)
                }
                catch { print("failed fetching personal leaderboard") }
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

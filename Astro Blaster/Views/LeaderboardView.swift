//
//  SettingsPanel.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 19.01.26.
//

import SwiftUI

struct LeaderboardView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State var scores : [ScoreEntry] = []
    
    var body: some View {
        VStack {
            //Back Button
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
            
            //Header
            Text("Leaderboard")
                .font(.custom("ArcadeInterlaced", size: 28))
                .foregroundColor(.green)
                .padding(.bottom, 10)
            
            //Sorted List of all All-Time Highscores of every Player
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
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear() {
            Task {
                do {
                    var seenPlayers : Set<String> = []
                    var filteredScores: [ScoreEntry] = []
                    //Backend Call to get each Players Scores
                    let service = BackendService()
                    scores = try await service.fetchGlobalLeaderboard()
                    //Array where each Player only Occurs once, so Backend Call Needs to be Filtered
                    filteredScores = scores.filter {entry in
                        //If Player was already Displayed before, this Score is not the Players highest and therefore does not need to be Displayed again
                        if seenPlayers.contains(entry.playerName){
                            return false
                        //If Player was not seen before this Score is the Players highest and there should be Displayed
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

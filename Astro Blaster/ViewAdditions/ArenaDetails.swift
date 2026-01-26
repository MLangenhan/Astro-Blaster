//
//  ArenaDetails.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 14.12.25.
//

import Foundation
import SwiftUI
import CoreLocation

//Arena Details Sheet
struct ArenaDetails: View {
    
    // The selected Arena
    let place: ArenaPlace
    // User Location, Optional if not loaded
    let userLocation: CLLocation?
    // Arena Difficulty
    let difficulty: Int
    // Action to Close the Sheet
    let onClose: () -> Void
    // New Closure for Full-Screen Navigation
    let onOpenFullScreen: () -> Void
    // Variable for Database
    @State var arenaScores : [ScoreEntry] = []
    //Show Highscore Panel
    @State private var showHighscores = false

    // Calculate Distance from Player to Arena with coordinates
    private var distanceInMeters: Double? {
        guard let userLocation else { return nil }

        let arenaLocation = CLLocation(
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude
        )

        return userLocation.distance(from: arenaLocation)
    }

    // Distance has to be below or equal to 200 Meters
    private var isInRange: Bool {
        guard let distanceInMeters else { return false }
        return distanceInMeters <= 200000000
    }
    
    var body: some View {
        VStack(spacing: 16) {

            // Arena Name displayed on top
            Text(place.name)
                .font(.custom("ArcadeInterlaced", size: 24))
                .foregroundColor(.green)

            // Arena Description
            Text(place.description)
                .font(.custom("ArcadeInterlaced", size: 15))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Divider()
                .background(Color.green)

            // Buttons
            HStack(spacing: 20) {
                // Calls the Closure to Close the Sheet
                Button("Close") {
                    onClose()
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .font(.custom("ArcadeInterlaced", size: 12))

                Button("FIGHT!!!") {
                    // Trigger Full-Screen Navigation
                    onOpenFullScreen()
                }
                .disabled(!isInRange)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .font(.custom("ArcadeInterlaced", size: 12))
            }

            // Check if User is in Range of Arena
            if let distance = distanceInMeters {
                Text(isInRange
                     ? "🟢 Arena Is Within Reach (\(Int(distance)) m)"
                     : "🔴 Arena Is Too Far Away (\(Int(distance)) m)")
                    .font(.custom("ArcadeInterlaced", size: 12))
                    .foregroundColor(.white)
            } else {
                Text("📍 Standort is being determined …")
                    .font(.custom("ArcadeInterlaced", size: 12))
                    .foregroundColor(.white)
            }

            Divider()
                .background(Color.green)
            
            // Highscore for Arena Button
            Button("Highscores of \(place.name)") {
                showHighscores = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .font(.custom("ArcadeInterlaced", size: 12))
        }
        .onAppear {
            Task {
                do {
                    var seenPlayers : Set<String> = []
                    var filteredScores: [ScoreEntry] = []
                    //Backend Call to get each Players Scores
                    let service = BackendService()
                    arenaScores = try await service.fetchArenaHighscores(arenaId: place.id)
                    //Array where each Ülayer only occurs once, so Backend Call needs to be Filtered
                    filteredScores = arenaScores.filter {entry in
                        //If Player was already Displayed before, this Score is not the Players highest and there does not need to be Displayed again
                        if seenPlayers.contains(entry.playerName){
                            return false
                        //If Player was not seen before this Score is the Players highest and there should be Displayed
                        } else {
                            seenPlayers.insert(entry.playerName)
                            return true
                        }
                    }
                    arenaScores = filteredScores
                } catch {
                    print("Failed to fetch highscores:", error)
                }
            }
        }
        .padding()
        // Limit the Sheet Height
        .presentationDetents([.height(250)])
        .fullScreenCover(isPresented: $showHighscores) {
            HighscoreView(scores: $arenaScores)
        }
        .ignoresSafeArea()
    }
}

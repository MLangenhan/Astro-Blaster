//
//  ArenaDetails.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 14.12.25.
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Arena Details Sheet
struct ArenaDetails: View {
    
    let place: ArenaPlace                   // The selected arena
    let userLocation: CLLocation?           // User location
    let difficulty: Int                     // Arena difficulty
    let onClose: () -> Void                 // Action to close the sheet
    let onOpenFullScreen: () -> Void        // New closure for full-screen navigation
    
    @State private var showHighscores = false //Show highscore panel
    
    var playerscores: [String: Int] = [
        "Alice": 95,
        "Bob": 82,
        "Charlie": 90,
        "Nova": 1870,
        "Liam": 1240,
        "Mila": 760,
        "Orion": 1995,
        "Zara": 430,
        "Elias": 1580,
        "Luna": 980,
        "Kai": 310,
        "Freya": 1425,
        "Noah": 670,
        "Ivy": 185,
        "Atlas": 1320,
        "Mason": 540,
        "Aria": 1760,
        "Finn": 860,
        "Skye": 225,
        "Leo": 1490
    ]

    // Calculate distance to arena
    private var distanceInMeters: Double? {
        guard let userLocation else { return nil }

        let arenaLocation = CLLocation(
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude
        )

        return userLocation.distance(from: arenaLocation)
    }

    // Distance has to be under or equal 200 meters
    private var isInRange: Bool {
        guard let distanceInMeters else { return false }
        return distanceInMeters <= 200
    }
    
    var body: some View {
        VStack(spacing: 16) {

            // MARK: - Title
            Text(place.name)
                .font(.custom("ArcadeInterlaced", size: 24))
                .foregroundColor(.green)

            // MARK: - Description
            Text(place.description)
                .font(.custom("ArcadeInterlaced", size: 15))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Divider()
                .background(Color.green) // grüne Divider

            // MARK: - Buttons
            HStack(spacing: 20) {
                
                Button("Close") {
                    onClose()               // Calls the closure to close the sheet
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .font(.custom("ArcadeInterlaced", size: 12))

                Button("FIGHT!!!") {
                    onOpenFullScreen()      // Trigger full-screen navigation
                }
                .disabled(!isInRange)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .font(.custom("ArcadeInterlaced", size: 12))
            }

            // MARK: - Check if User near the arena
            if let distance = distanceInMeters {
                Text(isInRange
                     ? "🟢 In Reichweite (\(Int(distance)) m)"
                     : "🔴 Zu weit entfernt (\(Int(distance)) m)")
                    .font(.custom("ArcadeInterlaced", size: 12))
                    .foregroundColor(.white)
            } else {
                Text("📍 Standort wird ermittelt …")
                    .font(.custom("ArcadeInterlaced", size: 12))
                    .foregroundColor(.white)
            }

            Divider()
                .background(Color.green)
            
            // MARK: - Highscore Button
            Button("Highscores of \(place.name)") {
                showHighscores = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .font(.custom("ArcadeInterlaced", size: 12))

        }
        .padding() // Limit the sheet height
        .presentationDetents([.height(250)])
        .fullScreenCover(isPresented: $showHighscores) {
            HighscoreView(place: place)
        }
        .ignoresSafeArea()
    }
}

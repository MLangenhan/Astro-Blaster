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
    let onClose: () -> Void                 // Action to close the sheet
    let onOpenFullScreen: () -> Void        // New closure for full-screen navigation

    // Calculate distance to arena
    private var distanceInMeters: Double? {
        guard let userLocation else { return nil }

        let arenaLocation = CLLocation(
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude
        )

        return userLocation.distance(from: arenaLocation)
    }

    // Distance has to be under or equal 100 meters
    private var isInRange: Bool {
        guard let distanceInMeters else { return false }
        return distanceInMeters <= 100
    }
    
    var body: some View {
        VStack(spacing: 16) {
            
            // MARK: - Title
            Text(place.name)
                .font(.title2)
                .bold()
            
            // MARK: - Description
            Text(place.description)
                .font(.body)
                .multilineTextAlignment(.center)
                            
            
            Divider()
            
            // MARK: - Check if User near the arena
            if let distance = distanceInMeters {
                Text(isInRange
                     ? "🟢 In Reichweite (\(Int(distance)) m)"
                     : "🔴 Zu weit entfernt (\(Int(distance)) m)")
                    .font(.headline)
            } else {
                Text("📍 Standort wird ermittelt …")
            }
            
            // MARK: - Buttons
            HStack(spacing: 20) {
                
                Button("Close") {
                    onClose()               // Calls the closure to close the sheet
                }
                .buttonStyle(.bordered)
                
                Button("FIGHT!!!") {
                    onOpenFullScreen()      // Trigger full-screen navigation
                }
                .disabled(!isInRange)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        // Limit the sheet height
        .presentationDetents([.height(250)])
    }
}

// MARK: - Preview
#Preview {
    ArenaDetails(
        place: ArenaPlace(
            name: "Test Arena",
            description: "Description",
            coordinate: .init(latitude: 0, longitude: 0)
        ),
        userLocation: CLLocation(latitude: 50.77560, longitude: 6.08370), // Fake Location
        onClose: {},
        onOpenFullScreen: {},
    )
}

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
    let onClose: () -> Void                 // Action to close the sheet
    let onOpenFullScreen: () -> Void        // New closure for full-screen navigation

    
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
            
            // MARK: - Buttons
            HStack(spacing: 20) {
                
                Button("Close") {
                    onClose()               // Calls the closure to close the sheet
                }
                .buttonStyle(.bordered)
                
                Button("FIGHT!!!") {
                    onOpenFullScreen()      // Trigger full-screen navigation
                }
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
        onClose: {},
        onOpenFullScreen: {},
    )
}

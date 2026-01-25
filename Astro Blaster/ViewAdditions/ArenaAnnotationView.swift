//
//  ArenaAnnotationView.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 19.01.26.
//

import SwiftUI
import CoreLocation

struct ArenaAnnotationView: View {
    // Arena informations, important for Location
    let place: ArenaPlace
    // Size of Arena Icon
    let scale: CGFloat
    // User location
    let userLocation: CLLocation?

    // Is user near the Arena and can play it? Then: isNearby = True
    private var isNearby: Bool {
        guard let userLocation else { return false }

        let arenaLocation = CLLocation(
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude
        )
        
        // Only if distance < 200, Why? Arena active when <=200, but here we use 1 meter difference (less prone to errors)
        return userLocation.distance(from: arenaLocation) < 200
    }

    var body: some View {
        Image(systemName: "crown.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 28, height: 28)
            .padding(6)
            // If Player near Arena an can play it, then make it red. Else make it purple.
            .background(Circle().fill(isNearby ? Color.green : Color.purple))
            .foregroundColor(.yellow)
            .shadow(radius: 3)
            // Scale size of Annotation, if player zooms on Map
            .scaleEffect(scale)
    }
}


//#Preview {
//    ArenaAnnotationView()
//}

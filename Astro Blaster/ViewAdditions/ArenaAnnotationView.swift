//
//  ArenaAnnotationView.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 19.01.26.
//

import SwiftUI
import CoreLocation

struct ArenaAnnotationView: View {
    let place: ArenaPlace
    let scale: CGFloat
    let userLocation: CLLocation?

    private var isNearby: Bool {
        guard let userLocation else { return false }

        let arenaLocation = CLLocation(
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude
        )

        return userLocation.distance(from: arenaLocation) < 200
    }

    var body: some View {
        Image(systemName: "crown.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 28, height: 28)
            .padding(6)
            .background(Circle().fill(isNearby ? Color.red : Color.purple))
            .foregroundColor(.yellow)
            .shadow(radius: 3)
            // Scale size of Annotation, if player zooms on Map
            .scaleEffect(scale)
    }
}


//#Preview {
//    ArenaAnnotationView()
//}

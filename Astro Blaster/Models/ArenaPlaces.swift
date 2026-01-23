//
//  ArenaPlaces.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 23.01.26.
//

import Foundation
import CoreLocation

struct ArenaPlaces {

    static let all: [ArenaPlace] = [
        ArenaPlace(
            id: "dom-aachen",
            name: "Dom Aachen",
            description: "Fight at Dom Aachen.",
            difficulty: 14,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.77535,
                longitude: 6.08389
            )
        ),
        ArenaPlace(
            id: "rwth-aachen",
            name: "RWTH Aachen",
            description: "Fight at RWTH Aachen.",
            difficulty: 4,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.77846,
                longitude: 6.06099
            )
        ),
        ArenaPlace(
            id: "tivoli",
            name: "Tivoli",
            description: "Fight at Tivoli.",
            difficulty: 6,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.793209,
                longitude: 6.098766
            )
        ),
        ArenaPlace(
            id: "end-game",
            name: "End Game",
            description: "Fight at End Game.",
            difficulty: 10,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.788902,
                longitude: 6.057804
            )
        )
    ]
}


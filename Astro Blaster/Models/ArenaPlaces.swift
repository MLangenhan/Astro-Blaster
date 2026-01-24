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
        // Germany - Aachen
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
        ),
        ArenaPlace(
            id: "uniklinik-aachen",
            name: "Aachen Hospital",
            description: "Fight at Aachen University Hospital.",
            difficulty: 8,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.77625724,
                longitude: 6.0437395
            )
        ),
        ArenaPlace(
            id: "hangeweiher-aachen",
            name: "Hangeweiher",
            description: "Fight at Hangeweiher.",
            difficulty: 5,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.76001382,
                longitude: 6.0724902080
            )
        ),
        ArenaPlace(
            id: "gillesbachtal-aachen",
            name: "Gillesbachtal",
            description: "Fight at Gillesbachtal.",
            difficulty: 4,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.7634547910,
                longitude: 6.102435106
            )
        ),
        ArenaPlace(
            id: "cemetery-aachen",
            name: "Cemetery",
            description: "Fight at Cemetery.",
            difficulty: 9,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.7537083994,
                longitude: 6.17001548754
            )
        ),
        ArenaPlace(
            id: "schonau-castle-aachen",
            name: "Schoenau Castle",
            description: "Fight at Schoenau Castle.",
            difficulty: 7,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.81128877990,
                longitude: 6.06414541520
            )
        ),
        ArenaPlace(
            id: "old-mill-bardenberg-kohlscheid",
            name: "Old Mill Bardenberg",
            description: "Fight at Old Mill Bardenberg.",
            difficulty: 3,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.83620738050,
                longitude: 6.1011959603110
            )
        ),
        // Netherlands - Vaals
        ArenaPlace(
            id: "kopermolen-vaals",
            name: "De Kopermolen",
            description: "Fight at De Kopermolen Vaals.",
            difficulty: 9,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.77018024,
                longitude: 6.019568
            )
        )
        
        
    ]
}


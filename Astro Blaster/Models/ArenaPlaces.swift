//
//  ArenaPlaces.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 23.01.26.
//

import Foundation
import CoreLocation

//All Arenas in Game
struct ArenaPlaces {

    static let all: [ArenaPlace] = [
        // Germany - Aachen
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
            id: "aquis-plaza-aachen",
            name: "Aquis Plaza",
            description: "Fight at Aquis Plaza.",
            difficulty: 12,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.7749089662122,
                longitude: 6.093987840550934
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
            id: "kennedypark-aachen",
            name: "Kennedypark",
            description: "Fight at Kennedypark.",
            difficulty: 5,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.77362327080901,
                longitude: 6.118821522963843
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
            id: "st-severin-aachen",
            name: "St. Severin",
            description: "Fight at St. Severin.",
            difficulty: 11,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.779076699922165,
                longitude: 6.152485372968039
            )
        ),
        // Germany - Kohlscheid
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
        // Germany - Würselen
        ArenaPlace(
            id: "rhine-maas-clinic-wurselen",
            name: "Rhine-Maas Clinic",
            description: "Fight at Rhine-Maas Clinic.",
            difficulty: 8,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.814995638332825,
                longitude: 6.1423868457917
            )
        ),
        // Germany - Stolberg
        ArenaPlace(
            id: "stolberg-castle-stolberg",
            name: "Stolberg Castle",
            description: "Fight at Stolberg Castle.",
            difficulty: 12,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.76714173212704,
                longitude: 6.2334094010763765
            )
        ),
        // Germany - Eschweiler
        ArenaPlace(
            id: "nothberg-castle-eschweiler",
            name: "Nothberg Castle",
            description: "Fight at Nothberg Castle.",
            difficulty: 4,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.81129275708187,
                longitude: 6.296849768430746
            )
        ),
        // Germany - Alsdorf
        ArenaPlace(
            id: "alsdorf-zoo-alsdorf",
            name: "Alsdorf Zoo",
            description: "Fight at Alsdorf Zoo.",
            difficulty: 6,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.864070444591015,
                longitude: 6.15126339551919
            )
        ),
        // Germany - Baesweiler
        ArenaPlace(
            id: "carl-alexander-park-baesweiler",
            name: "Carl Alexander Park",
            description: "Fight at Carl Alexander Park.",
            difficulty: 8,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.91007859474693,
                longitude: 6.157082809237758
            )
        ),
        // Netherlands - Vaals
        ArenaPlace(
            id: "kopermolen-vaals",
            name: "De Kopermolen",
            description: "Fight at De Kopermolen.",
            difficulty: 9,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.77018024,
                longitude: 6.019568
            )
        ),
        // Netherlands - Bocholtz
        ArenaPlace(
            id: "castle-de-bongard-bocholtz",
            name: "Castle De Bongard",
            description: "Fight at Castle De Bongard.",
            difficulty: 11,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.82274830205717,
                longitude: 6.002844802063363
            )
        ),
        // Netherlands - Kerkrade
        ArenaPlace(
            id: "parkstad-limburg-stadium-kerkrade",
            name: "Parkstad Limburg Stadium",
            description: "Fight at Parkstad Limburg Stadium.",
            difficulty: 7,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.82274830205717,
                longitude: 6.002844802063363
            )
        ),
        ArenaPlace(
            id: "erenstein-castle-kerkrade",
            name: "Erenstein Castle",
            description: "Fight at Erenstein Castle.",
            difficulty: 10,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.87186567128147,
                longitude: 6.054543392257442
            )
        ),
        // Netherlands - Landgraaf
        ArenaPlace(
            id: "mondo-verde-landgraaf",
            name: "Mondo Verde",
            description: "Fight at Mondo Verde.",
            difficulty: 6,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.88604346642915,
                longitude: 6.032114652796148
            )
        ),
        // Netherlands - Heerlen
        ArenaPlace(
            id: "meezenbroek-heerlen",
            name: "Meezenbroek",
            description: "Fight at Meezenbroek.",
            difficulty: 6,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.88604346642915,
                longitude: 6.032114652796148
            )
        ),
        // Belgium - Kelmis
        ArenaPlace(
            id: "museum-vieille-montagne-kelmis",
            name: "Museum Vieille Montagne",
            description: "Fight at Museum Vieille Montagne.",
            difficulty: 8,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.71164696031438,
                longitude: 6.008863804613452
            )
        ),
        // Belgium - Eynatten
        ArenaPlace(
            id: "eynatten-castle-eynatten",
            name: "Eynatten Castle",
            description: "Fight at Eynatten Castle.",
            difficulty: 10,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.69323284390655,
                longitude: 6.081618863961389
            )
        ),
        // Belgium - Eupen
        ArenaPlace(
            id: "marian-column-eupen",
            name: "Marian Column",
            description: "Fight at Marian Column.",
            difficulty: 9,
            coordinate: CLLocationCoordinate2D(
                latitude: 50.63087815444152,
                longitude: 6.03162013413452
            )
        )
        
        
        
    ]
}


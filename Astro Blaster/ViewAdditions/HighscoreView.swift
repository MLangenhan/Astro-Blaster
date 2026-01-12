//
//  HighscoreView.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 11.01.26.
//

import SwiftUI
import CoreLocation

struct HighscoreView: View {

    let place: ArenaPlace
    
    var scores: [String: Int] = [:] // Scores of the players
    
    private var sortedScores: [(key: String, value: Int)] {
        scores.sorted { $0.value > $1.value }
    } // Sorted scores
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // Back-Button
            HStack {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.headline)
                }

                Spacer()
            }
            .padding()

            Text("Highscores")
                .font(.largeTitle)
                .bold()

            List {
                // Show best 10 Scores
                ForEach(Array(sortedScores.prefix(10).enumerated()), id: \.element.key) { index, entry in
                    HStack {
                        Text("#\(index + 1)")
                            .bold()
                        
                        Spacer()
                        
                        Text(entry.key)
                        
                        Spacer()
                        
                        Text("\(entry.value) pts")
                    }
                }
            }
        }
    }
}


#Preview {
    HighscoreView(place: ArenaPlace(
        name: "Test Arena",
        description: "Description",
        coordinate: .init(latitude: 0, longitude: 0)
    ), scores: [
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
    )
}

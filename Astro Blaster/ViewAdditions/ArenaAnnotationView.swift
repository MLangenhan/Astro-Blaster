//
//  ArenaAnnotationView.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 19.01.26.
//

import SwiftUI

struct ArenaAnnotationView: View {
    let place: ArenaPlace

    var body: some View {
        //Used to Display Arena Locations on MapView
        Image(systemName: "crown.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 28, height: 28)
            .padding(6)
            .background(
                Circle().fill(Color.purple)
            )
            .foregroundColor(.yellow)
            .shadow(radius: 3)
    }
}

//#Preview {
//    ArenaAnnotationView()
//}

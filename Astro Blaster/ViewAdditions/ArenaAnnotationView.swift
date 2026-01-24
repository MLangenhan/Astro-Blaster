//
//  ArenaAnnotationView.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 19.01.26.
//

import SwiftUI

struct ArenaAnnotationView: View {
    let place: ArenaPlace
    let scale: CGFloat

    var body: some View {
        Image(systemName: "crown.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 28, height: 28)
            .padding(6)
            .background(Circle().fill(Color.purple))
            .foregroundColor(.yellow)
            .shadow(radius: 3)
            .scaleEffect(scale)
    }
}


//#Preview {
//    ArenaAnnotationView()
//}

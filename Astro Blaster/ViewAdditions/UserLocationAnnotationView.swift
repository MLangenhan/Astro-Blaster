//
//  UserLocationAnnotationView.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 19.01.26.
//

import SwiftUI

struct UserLocationAnnotationView: View {

    var body: some View {
        Image(systemName: "location.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
            .padding(6)
            .background(
                Circle()
                    .fill(Color.blue)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 2)
                    )
            )
            .foregroundColor(.white)
            .shadow(radius: 6)
    }
}


//#Preview {
//    UserLocationAnnotationView()
//}

//
//  CircleIconButton.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 19.01.26.
//

import SwiftUI

struct CircleIconButton: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .resizable()
            .scaledToFit()
            .frame(width: 25, height: 25)
            .foregroundColor(.white.opacity(0.9))
            .padding(18)
            .background(
                Circle()
                    .fill(Color.green)
                    .shadow(color: .green.opacity(0.6), radius: 6)
            )
    }
}

#Preview {
    CircleIconButton(systemImage: "person.fill")
}

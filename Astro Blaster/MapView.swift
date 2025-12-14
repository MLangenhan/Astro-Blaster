//
//  MapView.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 14.12.25.
//

import SwiftUI
import MapKit

struct MapView: View {
    var body: some View {
        Map()
            .mapStyle(.imagery)
    }
}

#Preview {
    MapView()
}

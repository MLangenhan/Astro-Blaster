//
//  SettingsPanel.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 19.01.26.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            
            // Back-Button
            HStack {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.custom("ArcadeInterlaced", size: 14))
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            .padding()
            
            // Highscore-Header
            Text("Settings")
                .font(.custom("ArcadeInterlaced", size: 28))
                .foregroundColor(.green)
                .padding(.bottom, 10)
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    SettingsView()
}

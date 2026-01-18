//
//  MapView.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 14.12.25.
//

import SwiftUI
import MapKit

// MARK: - Arena Places
// Represents an arena on the map with a name, description, and coordinates
struct ArenaPlace: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let coordinate: CLLocationCoordinate2D
}


// MARK: - Map View
struct MapView: View {
    
    // MARK: - User Location
    // Include LocationManager and check position
    @StateObject private var locationManager: LocationManager
    init(locationManager: LocationManager = LocationManager()) {
        _locationManager = StateObject(wrappedValue: locationManager)
    }
    
    // MARK: - State Properties
    @State private var selectedPlace: ArenaPlace?       // Currently selected place for showing details
    @State private var navigateToGameView = false       // Trigger full-screen navigation of GameView
    @State private var hasInitialCenterMoved = false    // Initial move of map only once
    
    // MARK: - Initial Map Camera Position
    // The map will start centered around Aachen
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.77664, longitude: 6.08342),
        span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
    ))
    
    // MARK: - Arena Locations
    // List of all arenas that will appear as annotations on the map
    private let places: [ArenaPlace] = [
        ArenaPlace(
            name: "Dom Aachen",
            description: "Fight at Dom Aachen.",
            coordinate: CLLocationCoordinate2D(
                latitude: 50.77535,
                longitude: 6.08389
            )
        ),
        ArenaPlace(
            name: "RWTH Aachen",
            description: "Fight at RWTH Aachen.",
            coordinate: CLLocationCoordinate2D(
                latitude: 50.77846,
                longitude: 6.06099
            )
        ),
        ArenaPlace(
            name: "Tivoli",
            description: "Fight at Tivoli.",
            coordinate: CLLocationCoordinate2D(
                latitude: 50.793209,
                longitude: 6.098766
            )
        ),
        ArenaPlace(
            name: "End Game",
            description: "Fight at End Game.",
            coordinate: CLLocationCoordinate2D(
                latitude: 50.788902,
                longitude: 6.057804
            )
        )
    ]
    
    
    // MARK: - Body
    var body: some View {
        
        ZStack{
            
            // Map view without default POIs
            Map(position: $cameraPosition) {
                ForEach(places) { place in
                    // Add a pin for each arena
                    Annotation(place.name, coordinate: place.coordinate) {
                        Image(systemName: "crown.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .padding(6)
                            .background(Circle().fill(Color.purple))
                            .foregroundColor(.yellow)
                            .shadow(radius: 3)
                            .onTapGesture {                     // Select the place when the pin is tapped
                                selectedPlace = place
                            }
                    }
                }
                
                // User-Location
                if let userLocation = locationManager.userLocation {
                    Annotation("You", coordinate: userLocation.coordinate) {
                            Image(systemName: "location.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                                .padding(4)
                                .background(Circle().fill(Color.blue.opacity(0.8)))
                                .foregroundColor(.white)
                                .shadow(radius: 3)
                        }
                }
            }
            .mapStyle(.standard(                  // Settings for Myterious Map
                elevation: .flat,
                emphasis: .muted,
                pointsOfInterest: .excludingAll
                               ))
            .preferredColorScheme(.dark)
            .onAppear {
                // Small latency, that map is loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Only once
                    if !hasInitialCenterMoved {
                        // Create new position
                        if let initialRegion = cameraPosition.region {
                            var newRegion = initialRegion
                            newRegion.center.latitude += 0.00001
                            // Move to new position
                            withAnimation(.none) {
                                cameraPosition = .region(newRegion)
                            }
                            hasInitialCenterMoved = true
                            // Move back to old position
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.none) {
                                    // Reset position
                                    newRegion.center.latitude -= 0.00001
                                    cameraPosition = .region(newRegion)
                                }
                            }
                        }
                    }
                }
            }
            // Show a bottom sheet when a place is selected
            .sheet(item: $selectedPlace) { place in
                ArenaDetails(
                    place: place,
                    userLocation: locationManager.userLocation,
                    onClose: { selectedPlace = nil },
                    onOpenFullScreen: {
                        // Close sheet
                        selectedPlace = nil
                        // Set state for GameView
                        navigateToGameView = true
                        // Set state for HighScore Table
                    }
                )
            }
            .fullScreenCover(isPresented: $navigateToGameView) {
                //MARK:  This only Active If player is near the point!!! LATER ....
                GameView(maxDifficulty: 5, isPresented: $navigateToGameView)
            }
            
            Rectangle()
                .fill(.black.opacity(0.15))
                .ignoresSafeArea()
                .colorMultiply(.purple.opacity(1))
                .allowsHitTesting(false)
            
            // --- Title as overlay ---
                VStack {
                    Text("ASTRO BLASTER")
                        .font(.custom("ArcadeInterlaced", size: 27))
                        .foregroundColor(.green)
                        .shadow(color: .purple, radius: 4, x: 2, y: 2)
                        .padding(.top, 10)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Preview
#Preview {
    MapView()
}

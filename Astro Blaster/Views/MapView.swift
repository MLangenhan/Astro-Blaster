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
    let coordinate: CLLocationCoordinate2D}


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
    @State private var showProfile = false              // Show profile
    @State private var showSettings = false             // Show settings
    @State private var initialRegionSet = false // Track, ob wir schon auf User zentriert haben


    
    // MARK: - Initial Map Camera Position
    // The map will start centered around Aachen
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.77664, longitude: 6.08342),
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
                    Annotation(place.name, coordinate: place.coordinate) {
                        ArenaAnnotationView(place: place)
                            .onTapGesture {
                                selectedPlace = place
                            }
                    }
                }
                
                // User-Location
                if let userLocation = locationManager.userLocation {
                    Annotation("You", coordinate: userLocation.coordinate) {
                        UserLocationAnnotationView()
                    }
                }
            }
            .onChange(of: locationManager.userLocation) { _, newLocation in
                guard let userLocation = newLocation, !initialRegionSet else { return }

                let region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
                )

                withAnimation(.easeInOut(duration: 0.5)) {
                    cameraPosition = .region(region)
                }

                initialRegionSet = true
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
                    GameView(maxDifficulty: 14, isPresented: $navigateToGameView)
            }
            
            Rectangle()
                .fill(.black.opacity(0.15))
                .ignoresSafeArea()
                .colorMultiply(.purple.opacity(1))
                .allowsHitTesting(false)
            
            // Own VStack for Headline, because allowsHitTesting = false
            VStack{
                Text("ASTRO BLASTER")
                    .font(.custom("ArcadeInterlaced", size: 38))
                    .foregroundColor(.green)
                    .shadow(color: .purple, radius: 4, x: 2, y: 2)
                    .padding(.top, 5)
                
                Spacer()
            }
            .allowsHitTesting(false)
            
            // Own VStack for Headline, because allowsHitTesting = true
            VStack {
                Spacer()

                HStack(spacing: 38) {

                    // Profile Button
                    CircleIconButton(systemImage: "person.fill")
                        .onTapGesture {
                            showProfile = true
                        }

                    // Settings Button
                    CircleIconButton(systemImage: "gearshape.fill")
                        .onTapGesture {
                            showSettings = true
                        }

                }
                .padding(.bottom, 40)
                .opacity(selectedPlace == nil ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: selectedPlace == nil)
                .allowsHitTesting(selectedPlace == nil)
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
                .sheet(isPresented: $showProfile) {
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    MapView()
}

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
    let id: String
    let name: String
    let description: String
    let difficulty: Int
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
    @State private var arenaDifficulty = 10              // Show profile
    @State private var hasInitialCenterMoved = false    // Initial move of map only once
    @State private var showProfile = false              // Show profile
    @State private var showSettings = false             // Show settings
    @State private var initialRegionSet = false // Track, ob wir schon auf User zentriert haben

    @State private var pendingArenaId: String? = nil
    @State private var pendingArenaName: String? = nil

    
    // MARK: - Initial Map Camera Position
    // The map will start centered around Aachen
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.77664, longitude: 6.08342),
        span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
    ))
    @State private var displayedUserCoordinate: CLLocationCoordinate2D =
        CLLocationCoordinate2D(latitude: 40.77664, longitude: 6.08342) // User Position
    
    
    // MARK: - Body
    var body: some View {
        
        ZStack{
            // Map view without default POIs
            Map(position: $cameraPosition) {
                
                ForEach(ArenaPlaces.all) { place in
                    Annotation(place.name, coordinate: place.coordinate) {
                        ArenaAnnotationView(place: place)
                            .onTapGesture {
                                selectedPlace = place
                            }
                    }
                }
                
                // User-Location
                Annotation("You", coordinate: displayedUserCoordinate) {
                    UserLocationAnnotationView()
                }
                
            }
            .onChange(of: locationManager.userLocation) { _, newLocation in
                
                // User location update
                guard let userLocation = newLocation else { return }

                // User pin on real position
                withAnimation(.easeInOut(duration: 0.3)) {
                    displayedUserCoordinate = userLocation.coordinate
                }
                                
                guard !initialRegionSet else { return }

                let region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
                )

                cameraPosition = .region(region)
                
                hasInitialCenterMoved = true         // Dont change it animore in .onAppear
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
                                    // Only go back to old position, if player position not loaded yet
                                    if !initialRegionSet{
                                        cameraPosition = .region(newRegion)
                                    }
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
                    difficulty: 5,                      // later arena difficulty
                    onClose: { selectedPlace = nil },
                    onOpenFullScreen: {
                        // Capture arena parameters before dismissing the sheet
                        pendingArenaId = place.id
                        pendingArenaName = place.name
                        // Close sheet
                        selectedPlace = nil
                        // Arena difficulty
                        arenaDifficulty = place.difficulty
                        // Set state for GameView
                        // Present the game view
                        navigateToGameView = true
                    }
                )
            }
            .fullScreenCover(isPresented: $navigateToGameView, onDismiss: {
                // Clear pending values after dismissing GameView
                pendingArenaId = nil
                pendingArenaName = nil
            }) {
                if let id = pendingArenaId, let name = pendingArenaName {
                    GameView(
                        maxDifficulty: 14,
                        arenaId: id,
                        arenaName: name,
                        isPresented: $navigateToGameView
                    )
                } else {
                    EmptyView()
                }
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
                    CircleIconButton(systemImage: "trophy.fill")
                        .onTapGesture {
                            showSettings = true
                        }
                    
                    // Location Button
                    CircleIconButton(systemImage: "location.north.fill")
                        .rotationEffect(.degrees(45))
                        .onTapGesture {
                            guard let userLocation = locationManager.userLocation else { return }

                                    let region = MKCoordinateRegion(
                                        center: userLocation.coordinate,
                                        span: MKCoordinateSpan(
                                            latitudeDelta: 0.05,
                                            longitudeDelta: 0.05
                                        )
                                    )

                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        cameraPosition = .region(region)
                                    }
                            
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


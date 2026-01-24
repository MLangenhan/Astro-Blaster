//
//  MapView.swift
//  Astro Blaster
//
//  Created by Delsin Hoffmann on 14.12.25.
//

import SwiftUI
import MapKit

// Arena Places
// Represents an Arena on the Map with a Name, Description, and Coordinates
struct ArenaPlace: Identifiable {
    let id: String
    let name: String
    let description: String
    let difficulty: Int
    let coordinate: CLLocationCoordinate2D}

// Map View
struct MapView: View {
    
    // MARK: - User Location
    // Include LocationManager and check position
    @StateObject private var locationManager: LocationManager
    init(locationManager: LocationManager = LocationManager()) {
        _locationManager = StateObject(wrappedValue: locationManager)
    }
    
    // MARK: - State Properties
    // Currently Selected Place for Showing Details
    @State private var selectedPlace: ArenaPlace?
    // Trigger Full-Screen Navigation of GameView
    @State private var navigateToGameView = false
    // Show Profile
    @State private var arenaDifficulty = 10
    // Initial Move of Map only Once
    @State private var hasInitialCenterMoved = false
    // Show Profile
    @State private var showProfile = false
    // Show Settings
    @State private var showSettings = false
    // Track, if User is already Centered on Map
    @State private var initialRegionSet = false
    @State private var pendingArenaId: String? = nil
    @State private var pendingArenaName: String? = nil

    
    // MARK: - Initial Map Camera Position
    // The Map will Start centered around Aachen
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.77664, longitude: 6.08342),
        span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
    ))
    @State private var displayedUserCoordinate: CLLocationCoordinate2D =
        CLLocationCoordinate2D(latitude: 40.77664, longitude: 6.08342) // User Position
    
    
    // MARK: - Body
    var body: some View {
        
        ZStack{
            // Map View without Default Points of Interest
            Map(position: $cameraPosition) {
                
                ForEach(ArenaPlaces.all) { place in
                    Annotation(place.name, coordinate: place.coordinate) {
                        ArenaAnnotationView(place: place)
                            .onTapGesture {
                                selectedPlace = place
                            }
                    }
                }
                
                // User Location
                Annotation("You", coordinate: displayedUserCoordinate) {
                    UserLocationAnnotationView()
                }
                
            }
            .onChange(of: locationManager.userLocation) { _, newLocation in
                
                // User Location Update
                guard let userLocation = newLocation else { return }

                // User Pin on Real Position
                withAnimation(.easeInOut(duration: 0.3)) {
                    displayedUserCoordinate = userLocation.coordinate
                }
                                
                guard !initialRegionSet else { return }

                let region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
                )

                cameraPosition = .region(region)
                // Dont change it anymore in .onAppear
                hasInitialCenterMoved = true
                initialRegionSet = true
            }
            // Settings for a more Myterious-looking Map
            .mapStyle(.standard(
                elevation: .flat,
                emphasis: .muted,
                pointsOfInterest: .excludingAll
                               ))
            .preferredColorScheme(.dark)
            .onAppear {
                // Small Latency, that Map is Loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Only once
                    if !hasInitialCenterMoved {
                        // Create new Position
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
                                    // Only go back to old Position, if Player Position not Loaded yet
                                    if !initialRegionSet{
                                        cameraPosition = .region(newRegion)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // Show a Bottom Sheet when a Place is Selected
            .sheet(item: $selectedPlace) { place in
                ArenaDetails(
                    place: place,
                    userLocation: locationManager.userLocation,
                    // Can Edit each Arenas Difficulty
                    difficulty: 5,
                    onClose: { selectedPlace = nil },
                    onOpenFullScreen: {
                        // Capture Arena Parameters before Dismissing the Sheet
                        pendingArenaId = place.id
                        pendingArenaName = place.name
                        // Close Sheet
                        selectedPlace = nil
                        // Arena Difficulty
                        arenaDifficulty = place.difficulty
                        // Set State for GameView
                        // Present the GameView
                        navigateToGameView = true
                    }
                )
            }
            .fullScreenCover(isPresented: $navigateToGameView, onDismiss: {
                // Clear pending Values after Dismissing GameView
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
            
            // Own VStack for Buttons, because allowsHitTesting = true
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
                    LeaderboardView()
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


//
//  GameView.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 09.12.25.
//

import SwiftUI
import SpriteKit
internal import AVFAudio

struct GameView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel: GameViewModel
    @State private var scene: GameScene
    @State private var hasTimeElapsed = false
    @State var musicVolume: Float = 0.5
    @State private var soundEffectsEnabled = true
    private let arenaId: String
    private let arenaName: String

    //Initialized Arena with given Properties
    init(maxDifficulty: CGFloat,
             arenaId: String,
             arenaName: String,
         isPresented: Binding<Bool>
    ) {
        self._isPresented = isPresented
            self.arenaId = arenaId
            self.arenaName = arenaName

        let vm = GameViewModel(maxDifficulty: maxDifficulty,
                                   arenaId: arenaId,
                                   arenaName: arenaName
        )
        self._viewModel = StateObject(wrappedValue: vm)
        
        let newScene = GameScene()
        newScene.viewModel = vm
        self._scene = State(initialValue: newScene)
    }

    //Sets up Scene with Anchor-Point being the Middle of the Screen and the whole Screen being filled
    private func setupScene(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        scene.size = size
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scene.scaleMode = .aspectFill
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SpriteView(scene: scene)
                    .background(Color.black.opacity(0.3))
                    .ignoresSafeArea()
                    .statusBarHidden(true)
                    .gesture(
                        // No need to Distinguish between Tap and Drag, therefore minimumDistance: 0
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !viewModel.isGameOver else { return }
                                if value.translation.width == 0 { scene.beginDrag() }
                                scene.dragShip(by: value.translation.width)
                            }
                            .onEnded { _ in scene.beginDrag() }
                    )
                    .onAppear { setupScene(size: geo.size) }
                    .onChange(of: geo.size) { _, newSize in
                        setupScene(size: newSize)
                    }
                
                //Pause Button at the top right
                Button(action: {
                    scene.gamePause()
                    viewModel.setGamePause()
                }) {
                    Image(systemName: "pause.fill")
                        .font(.custom("ArcadeInterlaced", size: 24))
                        .background(.clear)
                }
                .foregroundColor(.green)
                .padding()
                .clipShape(RoundedRectangle(cornerRadius:  10))
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                
                //Check if Game is over to cast gameOverOverlay
                if viewModel.isGameOver {
                    gameOverOverlay
                }
                
                //Check if Game is paused to cast gamePausedOverlay
                if viewModel.isGamePaused {
                    gamePausedOverlay
                }
            }
        }
    }
    
    private var gameOverOverlay: some View {
        VStack(spacing: 30) {
            
            Spacer()
            
            Text("GAME OVER")
                .font(.custom("ArcadeInterlaced", size: 48))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            //Achieved Score
            Text("Score: \(viewModel.scoreValue)")
                .font(.custom("ArcadeInterlaced", size: 20))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            //Button to Restart Game
            Button(action: {
                viewModel.resetGame()
                scene.reset()
            }) {
                Text("Restart")
                    .font(.custom("ArcadeInterlaced", size: 24))
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(10)
            }
            .foregroundColor(.green)

            //Button to Return to Map
            Button(action: { isPresented = false }) {
                Text("Return to Map")
                    .font(.custom("ArcadeInterlaced", size: 24))
            }
            .foregroundColor(.white)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.75))
    }
    
    private var gamePausedOverlay: some View {
        ZStack{
            VStack(spacing: 30) {
                
                Spacer()
                
                Text("GAME PAUSED")
                    .font(.custom("ArcadeInterlaced", size: 48))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 18) {

                            // Background Music Slider
                            HStack(alignment: .center) {
                                Text("Volume")
                                    .font(.custom("ArcadeInterlaced", size: 12))
                                    .foregroundColor(.green)
                                    .frame(width: 150, alignment: .leading)

                                Slider(value: $musicVolume, in: 0...1, step: 0.1, label: {})
                                    .onChange(of: musicVolume) {
                                        scene.backgroundMusic?.setVolume(musicVolume, fadeDuration: 0)
                                    }
                                    .tint(.green)
                                    .frame(width: 180, height: 28)
                            }

                            // Sound Effect Toggle
                            HStack(alignment: .center) {
                                Text("SOUNDEFFECTS")
                                    .font(.custom("ArcadeInterlaced", size: 12))
                                    .foregroundColor(.green)
                                    .frame(width: 150, alignment: .leading)

                                Toggle("", isOn: $soundEffectsEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .green))
                                    .labelsHidden()
                                    .scaleEffect(0.9)
                                    .frame(height: 28)
                                    .onChange(of: soundEffectsEnabled) { _, newValue in
                                        scene.soundeffectsEnabled = newValue
                                    }
                            }
                        }
                        .frame(maxWidth: 360)
                        .frame(maxWidth: .infinity)
                
                Spacer()
                
                //Button to Continue Playing
                Button(action: {
                    scene.gameUnpause()
                    viewModel.setGameUnpause()
                }) {
                    Text("Continue")
                        .font(.custom("ArcadeInterlaced", size: 24))
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(10)
                }
                .foregroundColor(.green)
                
                //Button to Restart Game
                Button(action: {
                    viewModel.setGameUnpause()
                    viewModel.resetGame()
                    scene.reset()
                }) {
                    Text("Restart")
                        .font(.custom("ArcadeInterlaced", size: 24))
                        .padding()
                        .cornerRadius(10)
                }
                .foregroundStyle(.white)

                //Button to Return to Map
                Button(action: { isPresented = false }) {
                    Text("Return to Map")
                        .font(.custom("ArcadeInterlaced", size: 24))
                }
                .foregroundColor(.white)
                
                Spacer()
                    
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.75))
        }
    }
        
}


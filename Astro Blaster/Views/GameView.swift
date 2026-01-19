//
//  GameView.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 09.12.25.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel: GameViewModel
    @State private var scene: GameScene

   init(maxDifficulty: CGFloat, isPresented: Binding<Bool>) {
       self._isPresented = isPresented
       let vm = GameViewModel(maxDifficulty: maxDifficulty)
       self._viewModel = StateObject(wrappedValue: vm)
       
       let newScene = GameScene()
       newScene.viewModel = vm
       self._scene = State(initialValue: newScene)
    }

    private func setupScene(size: CGSize) {
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
                        // no need to distinguish between tap and drag
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !viewModel.isGameOver else { return }
                                if value.translation.width == 0 { scene.beginDrag() }
                                scene.dragShip(by: value.translation.width)
                            }
                            .onEnded { _ in scene.beginDrag() }
                    )
                    .onAppear { setupScene(size: geo.size) }
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
                if viewModel.isGameOver {
                    gameOverOverlay
                }
                if viewModel.isGamePaused {
                    gamePausedOverlay
                }
            }
        }
    }
    
    private var gameOverOverlay: some View {
        VStack(spacing: 30) {
            Text("GAME OVER")
                .font(.custom("ArcadeInterlaced", size: 48))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
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

            Button(action: { isPresented = false }) {
                Text("Return to Map")
                    .font(.custom("ArcadeInterlaced", size: 24))
            }
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.75))
    }
    
    private var gamePausedOverlay: some View {
        ZStack{
            VStack(spacing: 30) {
                Text("GAME PAUSED")
                    .font(.custom("ArcadeInterlaced", size: 48))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
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

                Button(action: { isPresented = false }) {
                    Text("Return to Map")
                        .font(.custom("ArcadeInterlaced", size: 24))
                }
                .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.75))
            Button(action: {
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.custom("ArcadeInterlaced", size: 24))
                    .background(.clear)
            }
            .foregroundColor(.green)
            .padding()
            .clipShape(RoundedRectangle(cornerRadius:  10))
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }
        
}

//
//  GameView.swift
//  Astro Blaster
//
//  Created by Moritz Langenhan on 09.12.25.
//

import Foundation
import SwiftUI
import SpriteKit

class GameScene: SKScene {
    let rectangleNode = SKShapeNode(rectOf: CGSize(width: 100, height: 100))
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        rectangleNode.fillColor = .red
        rectangleNode.strokeColor = .red
        rectangleNode.position = CGPoint(x: 0, y: 0)
        if rectangleNode.parent == nil {
            addChild(rectangleNode)
        }
    }
    
    func updateRectanglePosition(_ position: CGSize) {
        rectangleNode.position = CGPoint(x: position.width, y: -position.height)
    }
}

struct GameView: View {
    
    @State private var position: CGSize = .zero
    private let scene = GameScene()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.1)
                    .edgesIgnoringSafeArea(.all)
                SpriteView(scene: scene)
                    .ignoresSafeArea()
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                position = value.translation
                                scene.updateRectanglePosition(position)
                            }
                    )
            }
            .onAppear {
                scene.size = geometry.size
                scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                scene.updateRectanglePosition(position)
            }
        }
    }
}

#Preview {
    GameView()
}


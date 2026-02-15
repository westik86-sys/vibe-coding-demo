//
//  ParticleCanvasView.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 28.01.2026.
//

import SwiftUI

private let sharedContext: ParticleEffectContext = {
    do {
        return try ParticleEffectContext()
    } catch {
        fatalError("Context creation failed: \(error)")
    }
}()

struct ParticleCanvasView: UIViewRepresentable {
    
    var renderer: (_ contentScaleFactor: CGFloat, _ body: UnsafeMutablePointer<ParticleData>) -> Int
    
    func makeUIView(context: Context) -> ParticleEffectMetalView {
        ParticleEffectMetalView(context: sharedContext)
    }
    
    func updateUIView(_ uiView: ParticleEffectMetalView, context: Context) {
        let scaleFactor = uiView.contentScaleFactor
        uiView.updateParticles { renderer(scaleFactor, $0) }
    }
}

#Preview {
    ParticleCanvasView { _, particles in
        particles[0].position = [500, 500]
        particles[0].size = 200
        particles[0].color = [1, 0, 0, 0.5]
        
        particles[1].position = [550, 550]
        particles[1].size = 200
        particles[1].color = [0, 0, 1, 0.5]
        
        return 2
    }
}

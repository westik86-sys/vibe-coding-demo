//
//  ParticlePhysics.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 04.12.2025.
//

import SwiftUI

public struct ParticlePhysics: Equatable {
    public let randomForce: Double = 4.0
    public let fixedDistance: Double = 7.0
    
    public let fontSize: Double
    public let respectBounds: Bool
    
    public var levitationSpeed: Double = 0.0
    public var particleScale: Double = 0.0
    public var particleDensity: Double = 0.0
    
    public var textCenterX: Double = 0.0
    public var textCenterY: Double = 0.0
    public var textWidth: Double = 0.0
    public var textHeight: Double = 0.0
    
    public var effectiveParticleCount: Int {
        let particleCount = pow(textWidth * textHeight, 0.7)
        return Int(particleDensity * particleCount)
    }
    
    public var effectiveFixedDistance: Double {
        // Масштабируемое расстояние относительно размера шрифта
        return fixedDistance * (fontSize / 48.0)
    }
}

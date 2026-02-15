//
//  SensitiveMode+Environment.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 05.12.2025.
//

import SwiftUI

private struct SensitiveModeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct TextBoundsKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct LevitationSpeedKey: EnvironmentKey {
    static let defaultValue: Double = 1.6
}

private struct ParticleScaleKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

private struct ParticleDensityKey: EnvironmentKey {
    static let defaultValue: Double = 0.5
}

private struct TextRevealDelay: EnvironmentKey {
    static let defaultValue: Int = 60
}

private struct ParticleHidingDelay: EnvironmentKey {
    static let defaultValue: Int = 30
}

private struct TextRevealDuration: EnvironmentKey {
    static let defaultValue: Int = 150
}

private struct ParticleHidingDuration: EnvironmentKey {
    static let defaultValue: Int = 200
}

extension EnvironmentValues {
    var isSensitiveModeEnabled: Bool {
        get { self[SensitiveModeKey.self] }
        set { self[SensitiveModeKey.self] = newValue }
    }
    
    var showsTextBounds: Bool {
        get { self[TextBoundsKey.self] }
        set { self[TextBoundsKey.self] = newValue }
    }
    
    var levitationSpeed: Double {
        get { self[LevitationSpeedKey.self] }
        set { self[LevitationSpeedKey.self] = newValue }
    }
    
    var particleScale: Double {
        get { self[ParticleScaleKey.self] }
        set { self[ParticleScaleKey.self] = newValue }
    }
    
    var particleDensity: Double {
        get { self[ParticleDensityKey.self] }
        set { self[ParticleDensityKey.self] = newValue }
    }
    
    var textRevealDelay: Int {
        get { self[TextRevealDelay.self] }
        set { self[TextRevealDelay.self] = newValue }
    }
    
    var particleHidingDelay: Int {
        get { self[ParticleHidingDelay.self] }
        set { self[ParticleHidingDelay.self] = newValue }
    }
    
    var textRevealDuration: Int {
        get { self[TextRevealDuration.self] }
        set { self[TextRevealDuration.self] = newValue }
    }
    
    var particleHidingDuration: Int {
        get { self[ParticleHidingDuration.self] }
        set { self[ParticleHidingDuration.self] = newValue }
    }
}

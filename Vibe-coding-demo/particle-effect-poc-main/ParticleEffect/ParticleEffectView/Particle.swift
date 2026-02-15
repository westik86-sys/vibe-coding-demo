//
//  Particle.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 04.12.2025.
//

import simd

private enum Constants {
    static let arrivalThresholdSq = 0.25
    static let closeRange = 144.0
    static let noiseScale = 0.1
    static let flickerPhaseStep = 0.05
    static let flickerOpacityBase = 0.8
    static let flickerOpacityRange = 0.2
    static let flickerSizeBase = 1.0
    static let flickerSizeRange = 0.2
}

public struct Particle {
    private(set) var x: Double
    private(set) var y: Double
    let baseX: Double
    let baseY: Double
    let baseColor: SIMD4<UInt8>
    private let massInv: Double
    private var velocityX: Double = 0.0
    private var velocityY: Double = 0.0
    private var targetX: Double
    private var targetY: Double
    
    private var levitationPhaseX: Double
    private var levitationPhaseY: Double
    private let levitationAmplitudeX: Double
    private let levitationAmplitudeY: Double
    private var levitationSpeedX: Double
    private var levitationSpeedY: Double
    
    private(set) var flickerOpacity: Double = 1.0
    private(set) var flickerSize: Double = 1.0
    private var flickerPhase: Double
    private(set) var particleSize: Double
    
    init(
        positionX: Double,
        positionY: Double,
        baseX: Double,
        baseY: Double,
        baseColor: SIMD4<UInt8>,
        physics: ParticlePhysics,
        isExploding: Bool,
        mass: Double
    ) {
        self.x = positionX
        self.y = positionY
        self.baseX = baseX
        self.baseY = baseY
        self.baseColor = baseColor
        self.massInv = 1.0 / mass
        self.particleSize = Double.random(in: 0.5...1.5)
        
        // Initialize Random Effects
        self.flickerPhase = Double.random(in: 0...2 * .pi)
        self.levitationPhaseX = Double.random(in: 0...2 * .pi)
        self.levitationPhaseY = Double.random(in: 0...2 * .pi)
        self.levitationAmplitudeX = Double.random(in: 4.0...8.0)
        self.levitationAmplitudeY = Double.random(in: 3.0...8.0)
        
        let speedFactor = physics.levitationSpeed + (0.0037 * physics.fontSize + 0.19)
        self.levitationSpeedX = Double.random(in: 0.008...0.02) * speedFactor
        self.levitationSpeedY = Double.random(in: 0.008...0.01) * speedFactor
        
        let angle = Double.random(in: 0...2 * .pi)
        let rawTargetX = baseX + cos(angle) * physics.effectiveFixedDistance
        let rawTargetY = baseY + sin(angle) * physics.effectiveFixedDistance
        
        if physics.respectBounds {
            let maxFlickerSize = Constants.flickerSizeBase + Constants.flickerSizeRange
            let maxRenderedRadius = particleSize * maxFlickerSize * physics.particleScale
            
            let marginX = levitationAmplitudeX + maxRenderedRadius
            let marginY = levitationAmplitudeY + maxRenderedRadius
            
            let minX = physics.textCenterX - physics.textWidth / 2 + marginX
            let maxX = physics.textCenterX + physics.textWidth / 2 - marginX
            let minY = physics.textCenterY - physics.textHeight / 2 + marginY
            let maxY = physics.textCenterY + physics.textHeight / 2 - marginY
            
            self.targetX = max(minX, min(rawTargetX, maxX))
            self.targetY = max(minY, min(rawTargetY, maxY))
        } else {
            self.targetX = rawTargetX
            self.targetY = rawTargetY
        }
        
        if isExploding {
            self.x = targetX
            self.y = targetY
        }
    }
    
    mutating func update(physics: ParticlePhysics, isExploding: Bool) {
        advanceLevitationPhase()

        let baseGoal = anchorPosition(isExploding: isExploding)
        let distSq = distanceSquared(to: baseGoal)

        if !isExploding && distSq < Constants.arrivalThresholdSq {
            snap(to: baseGoal)
            return
        }

        let approach = approachFactor(for: distSq)
        let finalTarget = blendedTarget(from: baseGoal, approach: approach, isExploding: isExploding)
        let finalDx = finalTarget.0 - x
        let finalDy = finalTarget.1 - y

        let frictionT = 1.0 - min(distSq / Constants.closeRange, 1.0)
        let stiffness: Double
        let friction: Double

        if isExploding {
            stiffness = 0.02 + (0.10 * frictionT)
            friction = 0.95 - (0.45 * frictionT)
        } else {
            stiffness = 0.10 + (0.25 * frictionT)
            friction = 0.52 - (0.12 * frictionT)
        }

        let springForceX = finalDx * stiffness
        let springForceY = finalDy * stiffness

        let noiseScale = (1.0 - approach) * physics.randomForce * Constants.noiseScale
        let noiseX = Double.random(in: -noiseScale...noiseScale)
        let noiseY = Double.random(in: -noiseScale...noiseScale)

        let accelX = (springForceX + noiseX) * massInv
        let accelY = (springForceY + noiseY) * massInv

        velocityX += accelX
        velocityY += accelY

        velocityX *= friction
        velocityY *= friction

        x += velocityX
        y += velocityY

        updateVisuals()
    }
    
    mutating func setMode(isExploding: Bool) {
        velocityX = 0
        velocityY = 0
        
        if isExploding {
            x = targetX
            y = targetY
        } else {
            x = baseX
            y = baseY
        }
    }
    
    mutating func scaleLevitationSpeed(by factor: Double) {
        levitationSpeedX *= factor
        levitationSpeedY *= factor
    }
}

// MARK: - Private helpers

private extension Particle {
    mutating func advanceLevitationPhase() {
        levitationPhaseX += levitationSpeedX
        levitationPhaseY += levitationSpeedY
    }
    
    mutating func snap(to anchor: (Double, Double)) {
        x = anchor.0
        y = anchor.1
        velocityX = 0
        velocityY = 0
    }
    
    mutating func updateVisuals() {
        flickerPhase += Constants.flickerPhaseStep
        flickerOpacity = Constants.flickerOpacityBase + Constants.flickerOpacityRange * sin(flickerPhase)
        flickerSize = Constants.flickerSizeBase + Constants.flickerSizeRange * sin(flickerPhase * 1.3)
    }
    
    func anchorPosition(isExploding: Bool) -> (Double, Double) {
        isExploding ? (targetX, targetY) : (baseX, baseY)
    }
    
    func distanceSquared(to target: (Double, Double)) -> Double {
        let dx = target.0 - x
        let dy = target.1 - y
        return dx * dx + dy * dy
    }
    
    func approachFactor(for distanceSq: Double) -> Double {
        max(0.0, min(1.0, 1.0 - (distanceSq / 25_000.0)))
    }
    
    func blendedTarget(from anchor: (Double, Double), approach: Double, isExploding: Bool) -> (Double, Double) {
        guard isExploding else { return anchor }
        let blend = approach * approach * approach
        let offsetX = sin(levitationPhaseX) * levitationAmplitudeX * blend
        let offsetY = sin(levitationPhaseY) * levitationAmplitudeY * blend
        return (anchor.0 + offsetX, anchor.1 + offsetY)
    }
}

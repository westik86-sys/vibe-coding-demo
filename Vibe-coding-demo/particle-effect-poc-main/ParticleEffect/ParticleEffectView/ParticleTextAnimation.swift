//
//  ParticleTextAnimation.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 04.12.2025.
//

import Combine
import SwiftUI

private enum Constants {
    static let alphaThreshold: UInt8 = 32
    static let frameInterval: TimeInterval = 1.0 / 60.0
    static let startEdgeOffset: Double = 0.5
}

public struct ParticleTextAnimation<Content: View>: View {
    let content: Content
    
    @Binding var physics: ParticlePhysics
    @Binding var isExploding: Bool
    
    @State private var particles: [Particle] = []
    @State private var canvasSize: CGSize = .zero
    @State private var timerCancellable: AnyCancellable?
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(
        content: Content,
        physics: Binding<ParticlePhysics>,
        isExploding: Binding<Bool>
    ) {
        self.content = content
        self._physics = physics
        self._isExploding = isExploding
    }
        
    public var body: some View {
        canvas
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .onChange(of: physics.levitationSpeed) { oldValue, newValue in
                let factor = oldValue == 0 ? 1.0 : newValue / oldValue
                for i in particles.indices {
                    particles[i].scaleLevitationSpeed(by: factor)
                }
            }
            .onChange(of: physics.particleDensity) { _, _ in
                syncParticleCount(to: physics.effectiveParticleCount)
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            handleGeometryChange(to: geometry.size)
                        }
                        .onChange(of: geometry.size) { _, newSize in
                            handleGeometryChange(to: newSize)
                        }
                        .onChange(of: colorScheme) { _, _ in
                            particles = createParticles()
                        }
                }
            )
    }
    
    private var canvas: some View {
        /*
        Canvas { context, size in
            context.blendMode = .normal
            
            for particle in particles {
                let particleSize = 2.0 * particle.particleSize * particle.flickerSize * physics.particleScale
                let particleOpacity = 0.8 * particle.flickerOpacity
                
                let path = Path(ellipseIn: CGRect(
                    x: particle.x - particleSize/2,
                    y: particle.y - particleSize/2,
                    width: particleSize,
                    height: particleSize
                ))
                let baseColor = Color(red: Double(particle.baseColor[0]) / 255.0,
                                      green: Double(particle.baseColor[1]) / 255.0,
                                      blue: Double(particle.baseColor[2]) / 255.0,
                                      opacity: Double(particle.baseColor[3]) / 255.0)
                context.fill(path, with: .color(baseColor.opacity(particleOpacity)))
            }
        }
        */
        
        ParticleCanvasView { scaleFactor, result in
            for (index, particle) in particles.enumerated() {
                let particleSize = 2.0 * particle.particleSize * particle.flickerSize * physics.particleScale
                let particleOpacity = 0.8 * particle.flickerOpacity
                
                let position =  SIMD2(Float(particle.x), Float(particle.y))
                var color = SIMD4<Float>(particle.baseColor) / 255.0
                color.w *= Float(particleOpacity)
                
                result[index].position = Float(scaleFactor) * position
                result[index].size = Float(scaleFactor * particleSize)
                result[index].color = color
            }
            
            return particles.count
        }
    }
    
    private func createParticles(targetCount: Int? = nil) -> [Particle] {
        guard canvasSize != .zero else { return [] }

        let renderer = ImageRenderer(content: content.colorScheme(colorScheme))
        renderer.scale = 1.0

        guard let image = renderer.uiImage,
              let cgImage = image.cgImage
        else { return [] }

        let textWidth = image.size.width
        let textHeight = image.size.height

        let textCenter = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let offsetX = Double((canvasSize.width - textWidth) / 2)
        let offsetY = Double((canvasSize.height - textHeight) / 2)

        physics.textCenterX = Double(textCenter.x)
        physics.textCenterY = Double(textCenter.y)
        physics.textWidth = Double(textWidth)
        physics.textHeight = Double(textHeight)

        let targetParticleCount = targetCount ?? physics.effectiveParticleCount
        return (0..<targetParticleCount).map { _ in
            var x, y: Int
            var color: SIMD4<UInt8>
            repeat {
                x = Int.random(in: 0..<cgImage.width)
                y = Int.random(in: 0..<cgImage.height)
                color = cgImage.pixelColor(x: x, y: y)
            } while color[3] < Constants.alphaThreshold
            
            let baseX = Double(x) + offsetX
            let baseY = Double(y) + offsetY

            let startX = baseX + Double.random(in: -Constants.startEdgeOffset...Constants.startEdgeOffset)
            let startY = baseY + Double.random(in: -Constants.startEdgeOffset...Constants.startEdgeOffset)

            let baseMass = 1.0
            let massVariation = 0.5
            let mass = baseMass + Double.random(in: -massVariation...massVariation)

            return Particle(
                positionX: startX,
                positionY: startY,
                baseX: baseX,
                baseY: baseY,
                baseColor: color,
                physics: physics,
                isExploding: isExploding,
                mass: max(0.1, mass)
            )
        }
    }
    
    private func updateParticles() {
        guard !particles.isEmpty else { return }
        for i in particles.indices {
            particles[i].update(physics: physics, isExploding: isExploding)
        }
    }
    
    private func startTimer() {
        guard timerCancellable == nil else { return }
        timerCancellable = Timer.publish(every: Constants.frameInterval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in updateParticles() }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func syncParticleCount(to target: Int) {
        let currentValue = particles.count
        
        if target < currentValue {
            var toRemoveCount = currentValue - target
            while toRemoveCount > 0 {
                if let i = particles.indices.randomElement() {
                    particles.remove(at: i)
                    toRemoveCount -= 1
                } else {
                    break
                }
            }
        } else if target > currentValue {
            let toAddCount = target - currentValue
            let newParticles = createParticles(targetCount: toAddCount)
            particles.append(contentsOf: newParticles)
        }
    }
    
    private func handleGeometryChange(to newSize: CGSize) {
        guard newSize != .zero else { return }
        let sizeChanged = canvasSize != newSize
        canvasSize = newSize
        if sizeChanged || particles.isEmpty {
            particles = createParticles()
        }
    }
}

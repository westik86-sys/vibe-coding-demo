//
//  ParticleEffectView.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 04.12.2025.
//

import SwiftUI

public struct ParticleEffectView<Content: View>: View {
    
    // MARK: - Properties
    let content: Content
    let tapToToggle: Bool
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    
    // MARK: - Environment
    
    @Environment(\.isSensitiveModeEnabled) private var isSensitiveModeEnabled
    @Environment(\.showsTextBounds) private var showsTextBounds
    @Environment(\.levitationSpeed) private var environmentLevitationSpeed
    @Environment(\.particleScale) private var environmentParticleScale
    @Environment(\.particleDensity) private var environmentParticleDensity
    @Environment(\.textRevealDelay) private var textRevealDelay
    @Environment(\.particleHidingDelay) private var particleHidingDelay
    @Environment(\.textRevealDuration) private var textRevealDuration
    @Environment(\.particleHidingDuration) private var particleHidingDuration
    
    @Environment(\.pixelLength) private var pixelLength
    
    // MARK: - State
    
    @State private var physics: ParticlePhysics
    @State private var isExploding: Bool = false
    @State private var showParticles: Bool = false
    @State private var textOpacity: Double = 1.0
    @State private var particleOpacity: Double = 0.0
    @State private var cleanupTask: Task<Void, Never>? = nil
    
    // MARK: - Initialization
    
    public init(
        content: Content,
        fontSize: CGFloat,
        respectBounds: Bool,
        tapToToggle: Bool
    ) {
        self.content = content
        self.tapToToggle = tapToToggle
        
        self.physics = ParticlePhysics(fontSize: fontSize, respectBounds: respectBounds)
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            content
                .opacity(textOpacity)
                .layoutPriority(100)
                .border(showsTextBounds ? Color.accentColor : Color.clear, width: pixelLength)
            
            if showParticles {
                ParticleTextAnimation(
                    content: content,
                    physics: $physics,
                    isExploding: $isExploding
                )
                .contentShape(Rectangle().inset(by: 15))
                .padding(-15)
                .opacity(particleOpacity)
            }
        }
        .onAppear(perform: setupInitialState)
        .onTapGesture {
            if tapToToggle {
                feedbackGenerator.impactOccurred()
                toggleEffect()
            }
        }
        .onChange(of: isSensitiveModeEnabled) { _, isEnabled in
            feedbackGenerator.impactOccurred()
            
            if isEnabled {
                startExplosion()
            } else {
                startGathering()
            }
        }
        .onChange(of: environmentLevitationSpeed) { _, val in physics.levitationSpeed = val }
        .onChange(of: environmentParticleScale) { _, val in physics.particleScale = val }
        .onChange(of: environmentParticleDensity) { _, val in physics.particleDensity = val }
    }
    
    // MARK: - Logic
    
    private func setupInitialState() {
        physics.levitationSpeed = environmentLevitationSpeed
        physics.particleScale = environmentParticleScale
        physics.particleDensity = environmentParticleDensity
        
        if isSensitiveModeEnabled {
            showParticles = true
            isExploding = true
            textOpacity = 0.0
            particleOpacity = 1.0
        }
    }
    
    private func toggleEffect() {
        if isExploding {
            startGathering()
        } else {
            startExplosion()
        }
    }
    
    private func startExplosion() {
        // 1. Отменяем любую запланированную задачу по скрытию частиц или показу текста
        cleanupTask?.cancel()
        cleanupTask = nil
        
        // 2. Гарантируем видимость частиц
        showParticles = true
        
        // 3. Задаем вектор "разлета"
        isExploding = true
        
        // 4. Прячем текст (частицы берут на себя визуал)
        withAnimation(.easeOut(duration: 0.15)) {
            textOpacity = 0.0
            particleOpacity = 1.0
        }
    }
    
    private func startGathering() {
        isExploding = false
        
        // 1. Возвращаем видимость текста
        let textRevealAnimation = Animation
            .easeIn(duration: Double(textRevealDuration) / 1000.0)
            .delay(Double(textRevealDelay) / 1000.0)
        let particleHidingAnimation = Animation
            .easeIn(duration: Double(particleHidingDuration) / 1000.0)
            .delay(Double(particleHidingDelay) / 1000.0)
        
        withAnimation(textRevealAnimation) { textOpacity = 1.0 }
        withAnimation(particleHidingAnimation) { particleOpacity = 0.0 }
        
        // 2. Планируем удаление тяжелого View частиц через Task (который можно отменить)
        cleanupTask = Task {
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return }
            
            await MainActor.run {
                if !isExploding {
                    showParticles = false
                }
            }
        }
    }
}

// MARK: - View Extension (Public API)

public extension View {
    
    func particleEffect(
        fontSize: CGFloat,
        respectBounds: Bool = true,
        tapToToggle: Bool = true
    ) -> some View {
        ParticleEffectView(
            content: self,
            fontSize: fontSize,
            respectBounds: respectBounds,
            tapToToggle: tapToToggle
        )
    }
}

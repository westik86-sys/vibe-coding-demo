//
//  AnimationSettingsView.swift
//  ParticleEffect
//
//  Created by Nestor on 12.12.2025.
//

import SwiftUI

struct AnimationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isSensitiveModeEnabled: Bool
    @Binding var showsTextBounds: Bool
    @Binding var levitationSpeed: Double
    @Binding var particleScale: Double
    @Binding var particleDensity: Double
    @Binding var textRevealDelay: Int
    @Binding var particleHidingDelay: Int
    @Binding var textRevealDuration: Int
    @Binding var particleHidingDuration: Int
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Скрытие данных", isOn: $isSensitiveModeEnabled)
                    Toggle("Границы текста", isOn: $showsTextBounds)
                }
                
                Section("Настройки анимации") {
                    Stepper(value: $levitationSpeed, in: 0.1...10.0, step: 0.1) {
                        Text("Скорость левитации: ") + Text(String(format: "%.1f", levitationSpeed)).bold()
                    }
                    Stepper(value: $particleScale, in: 0.5...2.0, step: 0.1) {
                        Text("Размер частиц: ") + Text(String(format: "%.1f", particleScale)).bold()
                    }
                    Stepper(value: $particleDensity, in: 0.1...1.0, step: 0.01) {
                        Text("Плотность частиц: ") + Text(String(format: "%.2f", particleDensity)).bold()
                    }
                }
                
                Section("Настройки времени") {
                    Stepper(value: $textRevealDelay, in: 0...1000, step: 5) {
                        Text("Задержка появления текста: ") + Text("\(textRevealDelay) мс").bold()
                    }
                    Stepper(value: $particleHidingDelay, in: 0...1000, step: 5) {
                        Text("Задержка скрытия частиц: ") + Text("\(particleHidingDelay) мс").bold()
                    }
                    Stepper(value: $textRevealDuration, in: 0...1000, step: 5) {
                        Text("Длительность появления текста: ") + Text("\(textRevealDuration) мс").bold()
                    }
                    Stepper(value: $particleHidingDuration, in: 0...1000, step: 5) {
                        Text("Длительность скрытия частиц: ") + Text("\(particleHidingDuration) мс").bold()
                    }
                }
            }
            .navigationTitle("Настройки анимации")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AnimationSettingsView(
        isSensitiveModeEnabled: .constant(false),
        showsTextBounds: .constant(false),
        levitationSpeed: .constant(3.0),
        particleScale: .constant(1.0),
        particleDensity: .constant(1.0),
        textRevealDelay: .constant(50),
        particleHidingDelay: .constant(50),
        textRevealDuration: .constant(150),
        particleHidingDuration: .constant(150)
    )
}

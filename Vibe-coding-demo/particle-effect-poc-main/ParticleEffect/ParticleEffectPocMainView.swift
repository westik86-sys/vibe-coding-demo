//
//  ContentView.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 04.12.2025.
//

import SwiftUI

struct ParticleEffectPocMainView: View {
    @State private var showsScreen63: Bool = false
    @State private var showsScreen660: Bool = false
    @State private var showsScreen1309: Bool = false
    @State private var showsScreen1310: Bool = false
    @State private var showsFocusAccount: Bool = false
    @State private var showsAnimationSettings: Bool = false
    
    // Environment Values
    static private let defaultValues = EnvironmentValues()
    @State private var isSensitiveModeEnabled: Bool = defaultValues.isSensitiveModeEnabled
    @State private var showsTextBounds: Bool = defaultValues.showsTextBounds
    @State private var levitationSpeed: Double = defaultValues.levitationSpeed
    @State private var particleScale: Double = defaultValues.particleScale
    @State private var particleDensity: Double = defaultValues.particleDensity
    @State private var textRevealDelay: Int = defaultValues.textRevealDelay
    @State private var particleHidingDelay: Int = defaultValues.particleHidingDelay
    @State private var textRevealDuration: Int = defaultValues.textRevealDuration
    @State private var particleHidingDuration: Int = defaultValues.particleHidingDuration
    
    var body: some View {
        List {
            Section("Экраны") {
                Button("63. События и операции") {
                    showsScreen63 = true
                }
                Button("660. Главная") {
                    showsScreen660 = true
                }
                Button("1309. Экран общей выгоды") {
                    showsScreen1309 = true
                }
                Button("1310. Основной экран выгоды") {
                    showsScreen1310 = true
                }
            }
            Section("Компоненты") {
                Button("Фокусный счёт") {
                    showsFocusAccount = true
                }
            }
        }
        .navigationTitle("Sensitive Mode")
        .sheet(isPresented: $showsScreen63) { settingsWrapper(for: screen63) }
        .sheet(isPresented: $showsScreen1309) { settingsWrapper(for: screen1309) }
        .sheet(isPresented: $showsFocusAccount) { settingsWrapper(for: focusAccount) }
        .fullScreenCover(isPresented: $showsScreen1310) { settingsWrapper(for: screen1310) }
        .fullScreenCover(isPresented: $showsScreen660) { settingsWrapper(for: screen660)}
    }
    
    // MARK: - 63. События и операции
    
    private var screen63: some View {
        NavigationStack {
            EventsAndOperationsView()
                .navigationTitle("Операции")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Закрыть") { showsScreen63 = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        topBarButtons
                    }
                }
        }
    }
    
    // MARK: - 660. Главная
    
    private var screen660: some View {
        HomeView()
            .overlay(alignment: .topLeading) {
                topBarButtons
                    .foregroundStyle(Color(.Text.primary))
                    .padding()
            }
            .overlay(alignment: .topTrailing) {
                CloseButton { showsScreen660 = false }
                    .padding()
            }
    }
    
    // MARK: - 1309. Экран общей выгоды
    
    private var screen1309: some View {
        NavigationStack {
            BenefitsAllTimeView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Закрыть") { showsScreen1309 = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        topBarButtons
                    }
                }
        }
    }
    
    // MARK: - 1310. Основной экран выгоды
    
    private var screen1310: some View {
        NavigationStack {
            BenefitsMainView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        topBarButtons
                            .foregroundStyle(Color(.Text.primary))
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        CloseButton { showsScreen1310 = false }
                    }
                }
                .environment(\.colorScheme, .dark)
        }
    }
    
    // MARK: - Компоненты
    
    private var focusAccount: some View {
        NavigationStack {
            FocusAccountView()
                .navigationTitle("Фокусный счёт")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Закрыть") { showsFocusAccount = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        topBarButtons
                    }
                }
        }
    }
    
    // MARK: - Экран настроек
    
    private func settingsScreen() -> some View {
        AnimationSettingsView(
            isSensitiveModeEnabled: $isSensitiveModeEnabled,
            showsTextBounds: $showsTextBounds,
            levitationSpeed: $levitationSpeed,
            particleScale: $particleScale,
            particleDensity: $particleDensity,
            textRevealDelay: $textRevealDelay,
            particleHidingDelay: $particleHidingDelay,
            textRevealDuration: $textRevealDuration,
            particleHidingDuration: $particleHidingDuration
        )
        .presentationDetents([.fraction(0.35), .large])
        .presentationDragIndicator(.automatic)
    }
    
    private func settingsWrapper<Content: View>(for content: Content) -> some View {
        content
            .sheet(isPresented: $showsAnimationSettings, content: settingsScreen)
            .environment(\.isSensitiveModeEnabled, isSensitiveModeEnabled)
            .environment(\.showsTextBounds, showsTextBounds)
            .environment(\.levitationSpeed, levitationSpeed)
            .environment(\.particleScale, particleScale)
            .environment(\.particleDensity, particleDensity)
            .environment(\.textRevealDelay, textRevealDelay)
            .environment(\.particleHidingDelay, particleHidingDelay)
            .environment(\.textRevealDuration, textRevealDuration)
            .environment(\.particleHidingDuration, particleHidingDuration)
    }
    
    private var topBarButtons: some View {
        HStack {
            Button(action: { isSensitiveModeEnabled.toggle() }) {
                Image(systemName: isSensitiveModeEnabled ? "eye" : "eye.slash")
            }
            Button(action: { showsAnimationSettings = true }) {
                Image(systemName: "gearshape")
            }
        }
        .imageScale(.large)
    }
}

private struct CloseButton: UIViewRepresentable {
    var action: () -> Void = {}
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .close)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .vertical)
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {
        let action = UIAction { _ in self.action() }
        uiView.addAction(action, for: .primaryActionTriggered)
    }
}

#Preview {
    ParticleEffectPocMainView()
}

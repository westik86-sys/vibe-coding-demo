import SwiftUI

private struct SexySensitiveModeSettings: Codable {
    var textOne: String = "Текст 1"
    var textTwo: String = "Текст 2"
    var showingFirstText: Bool = true
    var animationSpeed: Double = 26
    var animationDelay: Double = 0.1
    var phaseOneCycles: Int = 2
    var phaseTwoFramesPerCharacter: Int = 2
    var randomCharset: String = "_!X$0-+*#"
    var cursorCharacter: String = "_"

    static let `default` = SexySensitiveModeSettings()
}

struct SexySensitiveModeView: View {
    private static let settingsKey = "sexy_sensitive_mode_settings"

    @State private var isShowingSettings = false
    @State private var animationRestartID = UUID()
    @State private var animationSpeed: Double
    @State private var animationDelay: Double
    @State private var phaseOneCycles: Int
    @State private var phaseTwoFramesPerCharacter: Int
    @State private var randomCharset: String
    @State private var cursorCharacter: String
    @State private var textOne: String
    @State private var textTwo: String
    @State private var showingFirstText: Bool
    @State private var animationSourceText: String
    @State private var animationTargetText: String

    init() {
        let settings = Self.loadSettings()
        _animationSpeed = State(initialValue: settings.animationSpeed)
        _animationDelay = State(initialValue: settings.animationDelay)
        _phaseOneCycles = State(initialValue: settings.phaseOneCycles)
        _phaseTwoFramesPerCharacter = State(initialValue: settings.phaseTwoFramesPerCharacter)
        _randomCharset = State(initialValue: settings.randomCharset)
        _cursorCharacter = State(initialValue: settings.cursorCharacter)
        _textOne = State(initialValue: settings.textOne)
        _textTwo = State(initialValue: settings.textTwo)
        _showingFirstText = State(initialValue: settings.showingFirstText)
        _animationSourceText = State(initialValue: settings.showingFirstText ? settings.textOne : settings.textTwo)
        _animationTargetText = State(initialValue: settings.showingFirstText ? settings.textTwo : settings.textOne)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 12) {
                SpecialTextView(
                    animationTargetText,
                    initialText: animationSourceText,
                    replayTrigger: animationRestartID,
                    animateOnAppear: false,
                    configuration: animationConfiguration
                )
                    .font(.custom("Inter-Regular", size: 58))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .offset(y: -24)
        }
        .contentShape(Rectangle())
        .onAppear {
            syncDisplayedTexts()
        }
        .onChange(of: textOne) { _, _ in
            syncDisplayedTexts()
            persistSettings()
        }
        .onChange(of: textTwo) { _, _ in
            syncDisplayedTexts()
            persistSettings()
        }
        .onChange(of: showingFirstText) { _, _ in
            persistSettings()
        }
        .onChange(of: animationSpeed) { _, _ in
            persistSettings()
        }
        .onChange(of: animationDelay) { _, _ in
            persistSettings()
        }
        .onChange(of: phaseOneCycles) { _, _ in
            persistSettings()
        }
        .onChange(of: phaseTwoFramesPerCharacter) { _, _ in
            persistSettings()
        }
        .onChange(of: randomCharset) { _, _ in
            persistSettings()
        }
        .onChange(of: cursorCharacter) { _, _ in
            persistSettings()
        }
        .onTapGesture {
            animationSourceText = showingFirstText ? textOne : textTwo
            animationTargetText = showingFirstText ? textTwo : textOne
            showingFirstText.toggle()
            animationRestartID = UUID()
        }
        .navigationTitle("Sexy-sensetive-mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                Form {
                    Section("Text") {
                        TextField("Text 1", text: $textOne, axis: .vertical)
                            .lineLimit(2...6)

                        TextField("Text 2", text: $textTwo, axis: .vertical)
                            .lineLimit(2...6)
                    }

                    Section("Timing") {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledContent("Speed", value: "\(Int(animationSpeed)) ms")
                            Slider(value: $animationSpeed, in: 10...120, step: 1)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            LabeledContent("Delay", value: String(format: "%.2f s", animationDelay))
                            Slider(value: $animationDelay, in: 0...2, step: 0.05)
                        }
                    }

                    Section("Phases") {
                        Stepper("Phase 1 cycles: \(phaseOneCycles)", value: $phaseOneCycles, in: 1...8)
                        Stepper("Phase 2 frames per character: \(phaseTwoFramesPerCharacter)", value: $phaseTwoFramesPerCharacter, in: 1...6)
                    }

                    Section("Characters") {
                        TextField("Random charset", text: $randomCharset)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        TextField("Cursor character", text: $cursorCharacter)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    Section {
                        Button("Reset defaults") {
                            resetSettings()
                        }
                    }
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isShowingSettings = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var animationConfiguration: SpecialTextView.Configuration {
        .init(
            speed: UInt64(animationSpeed.rounded()),
            delay: animationDelay,
            phaseOneCycles: phaseOneCycles,
            phaseTwoFramesPerCharacter: phaseTwoFramesPerCharacter,
            randomCharset: randomCharset,
            cursorCharacter: cursorCharacter
        )
    }

    private func resetSettings() {
        let defaults = SexySensitiveModeSettings.default
        textOne = defaults.textOne
        textTwo = defaults.textTwo
        showingFirstText = defaults.showingFirstText
        animationSourceText = defaults.textOne
        animationTargetText = defaults.textTwo
        animationSpeed = defaults.animationSpeed
        animationDelay = defaults.animationDelay
        phaseOneCycles = defaults.phaseOneCycles
        phaseTwoFramesPerCharacter = defaults.phaseTwoFramesPerCharacter
        randomCharset = defaults.randomCharset
        cursorCharacter = defaults.cursorCharacter
        persistSettings()
    }

    private func syncDisplayedTexts() {
        if showingFirstText {
            animationSourceText = textOne
            animationTargetText = textTwo
        } else {
            animationSourceText = textTwo
            animationTargetText = textOne
        }
    }

    private func persistSettings() {
        let settings = SexySensitiveModeSettings(
            textOne: textOne,
            textTwo: textTwo,
            showingFirstText: showingFirstText,
            animationSpeed: animationSpeed,
            animationDelay: animationDelay,
            phaseOneCycles: phaseOneCycles,
            phaseTwoFramesPerCharacter: phaseTwoFramesPerCharacter,
            randomCharset: randomCharset,
            cursorCharacter: cursorCharacter
        )

        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: Self.settingsKey)
    }

    private static func loadSettings() -> SexySensitiveModeSettings {
        guard
            let data = UserDefaults.standard.data(forKey: settingsKey),
            let settings = try? JSONDecoder().decode(SexySensitiveModeSettings.self, from: data)
        else {
            return .default
        }

        return settings
    }
}

#Preview {
    NavigationStack {
        SexySensitiveModeView()
    }
}

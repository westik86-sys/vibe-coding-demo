import SwiftUI

private struct SexySensitiveModeSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case textOne
        case textTwo
        case textThree
        case currentTextIndex
        case showingFirstText
        case animationSpeed
        case animationDelay
        case phaseOneCycles
        case phaseTwoFramesPerCharacter
        case randomCharset
        case cursorCharacter
    }

    var textOne: String = "Текст 1"
    var textTwo: String = "Текст 2"
    var textThree: String = "Текст 3"
    var currentTextIndex: Int = 0
    var animationSpeed: Double = 26
    var animationDelay: Double = 0.1
    var phaseOneCycles: Int = 2
    var phaseTwoFramesPerCharacter: Int = 2
    var randomCharset: String = "_!X$0-+*#"
    var cursorCharacter: String = "_"

    static let `default` = SexySensitiveModeSettings()

    init(
        textOne: String = "Текст 1",
        textTwo: String = "Текст 2",
        textThree: String = "Текст 3",
        currentTextIndex: Int = 0,
        animationSpeed: Double = 26,
        animationDelay: Double = 0.1,
        phaseOneCycles: Int = 2,
        phaseTwoFramesPerCharacter: Int = 2,
        randomCharset: String = "_!X$0-+*#",
        cursorCharacter: String = "_"
    ) {
        self.textOne = textOne
        self.textTwo = textTwo
        self.textThree = textThree
        self.currentTextIndex = max(0, min(currentTextIndex, 2))
        self.animationSpeed = animationSpeed
        self.animationDelay = animationDelay
        self.phaseOneCycles = phaseOneCycles
        self.phaseTwoFramesPerCharacter = phaseTwoFramesPerCharacter
        self.randomCharset = randomCharset
        self.cursorCharacter = cursorCharacter
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        textOne = try container.decodeIfPresent(String.self, forKey: .textOne) ?? Self.default.textOne
        textTwo = try container.decodeIfPresent(String.self, forKey: .textTwo) ?? Self.default.textTwo
        textThree = try container.decodeIfPresent(String.self, forKey: .textThree) ?? Self.default.textThree

        if let currentTextIndex = try container.decodeIfPresent(Int.self, forKey: .currentTextIndex) {
            self.currentTextIndex = max(0, min(currentTextIndex, 2))
        } else if let showingFirstText = try container.decodeIfPresent(Bool.self, forKey: .showingFirstText) {
            self.currentTextIndex = showingFirstText ? 0 : 1
        } else {
            self.currentTextIndex = Self.default.currentTextIndex
        }

        animationSpeed = try container.decodeIfPresent(Double.self, forKey: .animationSpeed) ?? Self.default.animationSpeed
        animationDelay = try container.decodeIfPresent(Double.self, forKey: .animationDelay) ?? Self.default.animationDelay
        phaseOneCycles = try container.decodeIfPresent(Int.self, forKey: .phaseOneCycles) ?? Self.default.phaseOneCycles
        phaseTwoFramesPerCharacter = try container.decodeIfPresent(Int.self, forKey: .phaseTwoFramesPerCharacter) ?? Self.default.phaseTwoFramesPerCharacter
        randomCharset = try container.decodeIfPresent(String.self, forKey: .randomCharset) ?? Self.default.randomCharset
        cursorCharacter = try container.decodeIfPresent(String.self, forKey: .cursorCharacter) ?? Self.default.cursorCharacter
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(textOne, forKey: .textOne)
        try container.encode(textTwo, forKey: .textTwo)
        try container.encode(textThree, forKey: .textThree)
        try container.encode(currentTextIndex, forKey: .currentTextIndex)
        try container.encode(animationSpeed, forKey: .animationSpeed)
        try container.encode(animationDelay, forKey: .animationDelay)
        try container.encode(phaseOneCycles, forKey: .phaseOneCycles)
        try container.encode(phaseTwoFramesPerCharacter, forKey: .phaseTwoFramesPerCharacter)
        try container.encode(randomCharset, forKey: .randomCharset)
        try container.encode(cursorCharacter, forKey: .cursorCharacter)
    }
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
    @State private var textThree: String
    @State private var currentTextIndex: Int
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
        _textThree = State(initialValue: settings.textThree)
        _currentTextIndex = State(initialValue: max(0, min(settings.currentTextIndex, 2)))
        let texts = [settings.textOne, settings.textTwo, settings.textThree]
        let safeIndex = max(0, min(settings.currentTextIndex, 2))
        _animationSourceText = State(initialValue: texts[safeIndex])
        _animationTargetText = State(initialValue: texts[(safeIndex + 1) % texts.count])
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
                    .font(.system(size: 58, weight: .regular, design: .monospaced))
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
        .onChange(of: textThree) { _, _ in
            syncDisplayedTexts()
            persistSettings()
        }
        .onChange(of: currentTextIndex) { _, _ in
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
            let texts = orderedTexts
            animationSourceText = texts[currentTextIndex]
            currentTextIndex = (currentTextIndex + 1) % texts.count
            animationTargetText = texts[currentTextIndex]
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

                        TextField("Text 3", text: $textThree, axis: .vertical)
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
        textThree = defaults.textThree
        currentTextIndex = defaults.currentTextIndex
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
        let texts = orderedTexts
        let safeIndex = max(0, min(currentTextIndex, texts.count - 1))
        currentTextIndex = safeIndex
        animationSourceText = texts[safeIndex]
        animationTargetText = texts[(safeIndex + 1) % texts.count]
    }

    private func persistSettings() {
        let settings = SexySensitiveModeSettings(
            textOne: textOne,
            textTwo: textTwo,
            textThree: textThree,
            currentTextIndex: currentTextIndex,
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

    private var orderedTexts: [String] {
        [textOne, textTwo, textThree]
    }
}

#Preview {
    NavigationStack {
        SexySensitiveModeView()
    }
}

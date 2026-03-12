import SwiftUI

private struct SexySensitiveModeSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case texts
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

    var texts: [String] = ["Текст 1", "Текст 2", "Текст 3"]
    var currentTextIndex: Int = 0
    var animationSpeed: Double = 26
    var animationDelay: Double = 0.1
    var phaseOneCycles: Int = 2
    var phaseTwoFramesPerCharacter: Int = 2
    var randomCharset: String = "_!X$0-+*#"
    var cursorCharacter: String = "_"

    static let `default` = SexySensitiveModeSettings()

    init(
        texts: [String] = ["Текст 1", "Текст 2", "Текст 3"],
        currentTextIndex: Int = 0,
        animationSpeed: Double = 26,
        animationDelay: Double = 0.1,
        phaseOneCycles: Int = 2,
        phaseTwoFramesPerCharacter: Int = 2,
        randomCharset: String = "_!X$0-+*#",
        cursorCharacter: String = "_"
    ) {
        self.texts = Self.normalizedTexts(texts)
        self.currentTextIndex = max(0, min(currentTextIndex, self.texts.count - 1))
        self.animationSpeed = animationSpeed
        self.animationDelay = animationDelay
        self.phaseOneCycles = phaseOneCycles
        self.phaseTwoFramesPerCharacter = phaseTwoFramesPerCharacter
        self.randomCharset = randomCharset
        self.cursorCharacter = cursorCharacter
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedTexts = try container.decodeIfPresent([String].self, forKey: .texts)
        let legacyTexts = [
            try container.decodeIfPresent(String.self, forKey: .textOne),
            try container.decodeIfPresent(String.self, forKey: .textTwo),
            try container.decodeIfPresent(String.self, forKey: .textThree),
        ].compactMap { $0 }
        texts = Self.normalizedTexts(decodedTexts ?? legacyTexts)

        if let currentTextIndex = try container.decodeIfPresent(Int.self, forKey: .currentTextIndex) {
            self.currentTextIndex = max(0, min(currentTextIndex, texts.count - 1))
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
        try container.encode(texts, forKey: .texts)
        try container.encode(currentTextIndex, forKey: .currentTextIndex)
        try container.encode(animationSpeed, forKey: .animationSpeed)
        try container.encode(animationDelay, forKey: .animationDelay)
        try container.encode(phaseOneCycles, forKey: .phaseOneCycles)
        try container.encode(phaseTwoFramesPerCharacter, forKey: .phaseTwoFramesPerCharacter)
        try container.encode(randomCharset, forKey: .randomCharset)
        try container.encode(cursorCharacter, forKey: .cursorCharacter)
    }

    static func normalizedTexts(_ texts: [String]) -> [String] {
        let filtered = texts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if filtered.count >= 2 {
            return filtered
        }

        if filtered.count == 1 {
            return [filtered[0], "Текст 2"]
        }

        return Self.default.texts
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
    @State private var texts: [String]
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
        _texts = State(initialValue: settings.texts)
        _currentTextIndex = State(initialValue: max(0, min(settings.currentTextIndex, settings.texts.count - 1)))
        let safeIndex = max(0, min(settings.currentTextIndex, settings.texts.count - 1))
        _animationSourceText = State(initialValue: settings.texts[safeIndex])
        _animationTargetText = State(initialValue: settings.texts[(safeIndex + 1) % settings.texts.count])
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 12) {
                animatedPhraseView
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .offset(y: -24)
        }
        .contentShape(Rectangle())
        .onAppear {
            syncDisplayedTexts()
        }
        .onChange(of: texts) { _, _ in
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
                        ForEach(Array(texts.indices), id: \.self) { index in
                            TextField("Text \(index + 1)", text: $texts[index], axis: .vertical)
                                .lineLimit(2...6)

                            if texts.count > 2 {
                                Button("Delete Text \(index + 1)", role: .destructive) {
                                    deleteText(at: index)
                                }
                            }
                        }

                        Button("Add text") {
                            addText()
                        }
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

    private var animatedPhraseView: some View {
        let sourceParts = splitAnimatedParts(animationSourceText)
        let targetParts = splitAnimatedParts(animationTargetText)
        let canAnimateOnlySuffix = sourceParts.prefix == targetParts.prefix

        return Group {
            if canAnimateOnlySuffix {
                HStack(spacing: 0) {
                    Text(sourceParts.prefix)

                    SpecialTextView(
                        targetParts.animatedPart,
                        initialText: sourceParts.animatedPart,
                        replayTrigger: animationRestartID,
                        animateOnAppear: false,
                        configuration: animationConfiguration
                    )
                }
            } else {
                SpecialTextView(
                    animationTargetText,
                    initialText: animationSourceText,
                    replayTrigger: animationRestartID,
                    animateOnAppear: false,
                    configuration: animationConfiguration
                )
            }
        }
        .font(.system(size: 58, weight: .regular, design: .monospaced))
        .multilineTextAlignment(.center)
    }

    private func resetSettings() {
        let defaults = SexySensitiveModeSettings.default
        texts = defaults.texts
        currentTextIndex = defaults.currentTextIndex
        animationSourceText = defaults.texts[0]
        animationTargetText = defaults.texts[1]
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
            texts: texts,
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
        SexySensitiveModeSettings.normalizedTexts(texts)
    }

    private func splitAnimatedParts(_ text: String) -> (prefix: String, animatedPart: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let splitIndex = trimmed.firstIndex(of: " ") else {
            return ("", trimmed)
        }

        let nextIndex = trimmed.index(after: splitIndex)
        let prefix = String(trimmed[..<nextIndex])
        let suffix = String(trimmed[nextIndex...])
        return (prefix, suffix)
    }

    private func addText() {
        texts.append("Текст \(texts.count + 1)")
    }

    private func deleteText(at index: Int) {
        guard texts.count > 2, texts.indices.contains(index) else { return }

        texts.remove(at: index)

        if currentTextIndex >= texts.count {
            currentTextIndex = 0
        } else if index < currentTextIndex {
            currentTextIndex -= 1
        }

        syncDisplayedTexts()
        persistSettings()
    }
}

#Preview {
    NavigationStack {
        SexySensitiveModeView()
    }
}

import SwiftUI
import Security

private struct PrismShaderParams: Codable {
    var radius: Double
    var frequency: Double
    var speed: Double
    var falloffPower: Double
    var lensAmount: Double
    var rippleAmount: Double
    var chromaticBase: Double
    var chromaticWave: Double
    var redSplit: Double
    var blueSplit: Double
    var crestRed: Double
    var crestGreen: Double
    var crestBlue: Double
}

private struct PrismPreset: Identifiable, Codable {
    var id: UUID
    var name: String
    var params: PrismShaderParams
}

struct PrismEffectV2View: View {
    private static let presetsKey = "prism_effect_v2_presets"
    private static let keychainService = "com.vibe-coding-demo.prism-effect-v2"
    private static let keychainAccount = "shader-presets"

    @State private var touch: CGPoint = .init(x: -10_000, y: -10_000)
    @State private var intensity: CGFloat = 0
    @State private var isSettingsPresented = false

    @State private var radius: Double = 220
    @State private var frequency: Double = 0.145
    @State private var speed: Double = 9.2
    @State private var falloffPower: Double = 2.0
    @State private var lensAmount: Double = 20.0
    @State private var rippleAmount: Double = 28.0
    @State private var chromaticBase: Double = 8.0
    @State private var chromaticWave: Double = 10.0
    @State private var redSplit: Double = 0.95
    @State private var blueSplit: Double = 1.10
    @State private var crestRed: Double = 0.35
    @State private var crestGreen: Double = 0.10
    @State private var crestBlue: Double = 0.45

    @State private var presets: [PrismPreset] = []
    @State private var presetName: String = ""

    private var trimmedPresetName: String {
        presetName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var dynamicSampleOffset: CGFloat {
        CGFloat(max(lensAmount + abs(rippleAmount) + chromaticBase + chromaticWave, 120))
    }

    var body: some View {
        TimelineView(.animation) { context in
            let t = Float(context.date.timeIntervalSinceReferenceDate)

            ZStack {
                Color.black.ignoresSafeArea()

                Text("""
                БОЖЕ ХРАНИ Т-БАНК 🙏🏦 ЗА ЗАРПЛАТУ 🙏❤️ ПУСТЬ ПРИХОДИТ ВОВРЕМЯ ⏰✅ ПУСТЬ НЕ ПРОПАДАЕТ 📵🚫 СПАСИБО НАШИМ ДИЗАЙНЕРАМ  ЧТО СДЕЛАЛИ КРАСИВО И ПОНЯТНО 🎨📲 ДАЙ НАМ КЭШБЭК И ТЕРПЕНИЕ ❤️🙏 АНГЕЛА ХРАНИТЕЛЯ КАЖДОМУ ИЗ ВАС 🙏❤️ ПУСТЬ Т-БАНК  ДЕРЖИТСЯ КРЕПКО 🛡✨
                ПУСТЬ СЕРВЕРА СТОЯТ 🖥🧱
                ПУСТЬ НЕ ПАДАЕТ НИЧЕГО 📉🚫
                """)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .layerEffect(
                ShaderLibrary.prismRippleV2(
                    .float2(Float(touch.x), Float(touch.y)),
                    .float(Float(intensity)),
                    .float(t),
                    .float(Float(radius)),
                    .float(Float(frequency)),
                    .float(Float(speed)),
                    .float(Float(falloffPower)),
                    .float(Float(lensAmount)),
                    .float(Float(rippleAmount)),
                    .float(Float(chromaticBase)),
                    .float(Float(chromaticWave)),
                    .float(Float(redSplit)),
                    .float(Float(blueSplit)),
                    .float(Float(crestRed)),
                    .float(Float(crestGreen)),
                    .float(Float(crestBlue))
                ),
                maxSampleOffset: CGSize(width: dynamicSampleOffset, height: dynamicSampleOffset),
                isEnabled: intensity > 0.001
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        touch = v.location
                        intensity = 1
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.25)) {
                            intensity = 0
                        }
                    }
            )
        }
        .onAppear(perform: loadPresets)
        .navigationTitle("Prism-Effect-v2")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isSettingsPresented = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Shader settings")
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            NavigationStack {
                Form {
                    Section("Presets") {
                        HStack {
                            TextField("Preset name", text: $presetName)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                            Button("Save") {
                                savePreset()
                            }
                            .disabled(trimmedPresetName.isEmpty)
                        }

                        if presets.isEmpty {
                            Text("No presets yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(presets) { preset in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(preset.name)
                                        .font(.headline)
                                    HStack(spacing: 14) {
                                        Button("Load") {
                                            applyPreset(preset)
                                        }
                                        Button("Delete", role: .destructive) {
                                            deletePreset(preset)
                                        }
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    Section("Wave") {
                        sliderRow(title: "Radius", value: $radius, range: 40...500)
                        sliderRow(title: "Frequency", value: $frequency, range: 0.02...0.5)
                        sliderRow(title: "Speed", value: $speed, range: 0...25)
                        sliderRow(title: "Falloff Power", value: $falloffPower, range: 0.5...4)
                    }

                    Section("Distortion") {
                        sliderRow(title: "Lens", value: $lensAmount, range: 0...80)
                        sliderRow(title: "Ripple", value: $rippleAmount, range: 0...80)
                    }

                    Section("Chromatic") {
                        sliderRow(title: "Base", value: $chromaticBase, range: 0...30)
                        sliderRow(title: "Wave Boost", value: $chromaticWave, range: 0...30)
                        sliderRow(title: "Red Split", value: $redSplit, range: 0...2)
                        sliderRow(title: "Blue Split", value: $blueSplit, range: 0...2)
                    }

                    Section("Crest Tint") {
                        sliderRow(title: "Red", value: $crestRed, range: 0...1)
                        sliderRow(title: "Green", value: $crestGreen, range: 0...1)
                        sliderRow(title: "Blue", value: $crestBlue, range: 0...1)
                    }
                }
                .navigationTitle("Shader Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isSettingsPresented = false
                        }
                    }
                }
            }
        }
    }

    private func currentParams() -> PrismShaderParams {
        PrismShaderParams(
            radius: radius,
            frequency: frequency,
            speed: speed,
            falloffPower: falloffPower,
            lensAmount: lensAmount,
            rippleAmount: rippleAmount,
            chromaticBase: chromaticBase,
            chromaticWave: chromaticWave,
            redSplit: redSplit,
            blueSplit: blueSplit,
            crestRed: crestRed,
            crestGreen: crestGreen,
            crestBlue: crestBlue
        )
    }

    private func apply(params: PrismShaderParams) {
        radius = params.radius
        frequency = params.frequency
        speed = params.speed
        falloffPower = params.falloffPower
        lensAmount = params.lensAmount
        rippleAmount = params.rippleAmount
        chromaticBase = params.chromaticBase
        chromaticWave = params.chromaticWave
        redSplit = params.redSplit
        blueSplit = params.blueSplit
        crestRed = params.crestRed
        crestGreen = params.crestGreen
        crestBlue = params.crestBlue
    }

    private func savePreset() {
        let name = trimmedPresetName
        guard !name.isEmpty else { return }

        if let index = presets.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            presets[index].params = currentParams()
            presets[index].name = name
        } else {
            presets.append(PrismPreset(id: UUID(), name: name, params: currentParams()))
        }

        presets.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        persistPresets()
    }

    private func applyPreset(_ preset: PrismPreset) {
        presetName = preset.name
        apply(params: preset.params)
    }

    private func deletePreset(_ preset: PrismPreset) {
        presets.removeAll { $0.id == preset.id }
        persistPresets()
    }

    private func loadPresets() {
        if let data = keychainReadData(),
           let decoded = try? JSONDecoder().decode([PrismPreset].self, from: data) {
            presets = decoded.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return
        }

        // One-time migration for previously saved presets in UserDefaults.
        guard let legacyData = UserDefaults.standard.data(forKey: Self.presetsKey),
              let decoded = try? JSONDecoder().decode([PrismPreset].self, from: legacyData) else { return }
        presets = decoded.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        persistPresets()
        UserDefaults.standard.removeObject(forKey: Self.presetsKey)
    }

    private func persistPresets() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        _ = keychainUpsert(data: data)
    }

    private func keychainQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount
        ]
    }

    private func keychainReadData() -> Data? {
        var query = keychainQuery()
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func keychainUpsert(data: Data) -> Bool {
        var query = keychainQuery()
        let attributes: [String: Any] = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }

        query[kSecValueData as String] = data
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        return addStatus == errSecSuccess
    }

    @ViewBuilder
    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(3)))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }
}

#Preview {
    PrismEffectV2View()
}

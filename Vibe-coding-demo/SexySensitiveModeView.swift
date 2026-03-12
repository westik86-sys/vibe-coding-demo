import SwiftUI

struct SexySensitiveModeView: View {
    @State private var isShowingSettings = false
    @State private var animationRestartID = UUID()
    @State private var animationSpeed: Double = 26
    @State private var animationDelay: Double = 0.1
    @State private var phaseOneCycles = 2
    @State private var phaseTwoFramesPerCharacter = 2
    @State private var randomCharset = "_!X$0-+*#"
    @State private var cursorCharacter = "_"

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 12) {
                SpecialTextView(
                    "Ты пидор",
                    configuration: animationConfiguration
                )
                    .id(animationRestartID)
                    .font(.custom("Inter-Regular", size: 58))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .offset(y: -24)
        }
        .contentShape(Rectangle())
        .onTapGesture {
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
        let defaults = SpecialTextView.Configuration.default
        animationSpeed = Double(defaults.speed)
        animationDelay = defaults.delay
        phaseOneCycles = defaults.phaseOneCycles
        phaseTwoFramesPerCharacter = defaults.phaseTwoFramesPerCharacter
        randomCharset = defaults.randomCharset
        cursorCharacter = defaults.cursorCharacter
    }
}

#Preview {
    NavigationStack {
        SexySensitiveModeView()
    }
}

import SwiftUI

struct SpecialTextView: View {
    private enum Phase {
        case phase1
        case phase2
    }

    struct Configuration: Equatable {
        var speed: UInt64 = 20
        var delay: Double = 0
        var phaseOneCycles: Int = 2
        var phaseTwoFramesPerCharacter: Int = 2
        var randomCharset: String = "_!X$0-+*#"
        var cursorCharacter: String = "_"

        static let `default` = Configuration()
    }

    let text: String
    let initialText: String
    let replayTrigger: UUID
    let animateOnAppear: Bool
    let configuration: Configuration

    @State private var displayText: String
    @State private var currentPhase: Phase = .phase1
    @State private var animationStep = 0
    @State private var animationTask: Task<Void, Never>?

    init(
        _ text: String,
        initialText: String = "",
        replayTrigger: UUID = UUID(),
        animateOnAppear: Bool = true,
        configuration: Configuration = .default
    ) {
        self.text = text
        self.initialText = initialText
        self.replayTrigger = replayTrigger
        self.animateOnAppear = animateOnAppear
        self.configuration = configuration
        _displayText = State(initialValue: Self.normalizedDisplayText(initialText, to: max(text.count, initialText.count)))
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Reserve space for both states so switching between them does not
            // reflow the animated layer.
            Text(initialText)
                .opacity(0)

            Text(text)
                .opacity(0)

            Text(displayText)
        }
            .onAppear {
                if animateOnAppear {
                    startAnimation()
                } else {
                    displayText = initialDisplayText
                }
            }
            .onDisappear {
                animationTask?.cancel()
                animationTask = nil
            }
            .onChange(of: text) { _, _ in
                resetToInitialState()
            }
            .onChange(of: initialText) { _, _ in
                resetToInitialState()
            }
            .onChange(of: replayTrigger) { _, _ in
                startAnimation()
            }
            .onChange(of: configuration) { _, _ in
                resetToInitialState()
            }
    }

    private func resetToInitialState() {
        animationTask?.cancel()
        displayText = initialDisplayText
        currentPhase = .phase1
        animationStep = 0
    }

    private func startAnimation() {
        animationTask?.cancel()
        displayText = initialDisplayText
        currentPhase = .phase1
        animationStep = 0

        animationTask = Task {
            if configuration.delay > 0 {
                let delayNs = UInt64(configuration.delay * 1_000_000_000)
                try? await Task.sleep(nanoseconds: delayNs)
            }

            guard !Task.isCancelled else { return }

            guard initialDisplayText != finalDisplayText else {
                await MainActor.run {
                    displayText = finalDisplayText
                }
                return
            }

            while !Task.isCancelled {
                await MainActor.run {
                    switch currentPhase {
                    case .phase1:
                        runPhase1()
                    case .phase2:
                        runPhase2()
                    }
                }

                if displayText == finalDisplayText {
                    break
                }

                try? await Task.sleep(nanoseconds: configuration.speed * 1_000_000)
            }
        }
    }

    private func runPhase1() {
        let maxSteps = max(displayLength * max(configuration.phaseOneCycles, 1), 1)

        var chars: [Character] = []
        chars.reserveCapacity(displayLength)

        for index in 0..<displayLength {
            let previous = index > 0 ? chars[index - 1] : nil
            chars.append(randomChar(previous: previous))
        }

        displayText = String(chars)

        if animationStep < maxSteps - 1 {
            animationStep += 1
        } else {
            currentPhase = .phase2
            animationStep = 0
        }
    }

    private func runPhase2() {
        let characters = Array(finalDisplayText)
        let framesPerCharacter = max(configuration.phaseTwoFramesPerCharacter, 1)
        let revealedCount = animationStep / framesPerCharacter

        var chars: [Character] = []
        chars.reserveCapacity(displayLength)

        for index in 0..<min(revealedCount, characters.count) {
            chars.append(characters[index])
        }

        if revealedCount < characters.count {
            let cursor = cursorCharacter
            chars.append(animationStep.isMultiple(of: framesPerCharacter) ? cursor : randomChar(previous: nil))
        }

        while chars.count < displayLength {
            chars.append(randomChar(previous: chars.last))
        }

        displayText = String(chars)

        if animationStep < characters.count * framesPerCharacter - 1 {
            animationStep += 1
        } else {
            displayText = finalDisplayText
        }
    }

    private func randomChar(previous: Character?) -> Character {
        let charset = Array(configuration.randomCharset.isEmpty ? Configuration.default.randomCharset : configuration.randomCharset)
        var next = charset.randomElement() ?? "_"

        while previous == next, charset.count > 1 {
            next = charset.randomElement() ?? "_"
        }

        return next
    }

    private var cursorCharacter: Character {
        configuration.cursorCharacter.first ?? "_"
    }

    private var displayLength: Int {
        max(text.count, initialText.count)
    }

    private var initialDisplayText: String {
        Self.normalizedDisplayText(initialText, to: displayLength)
    }

    private var finalDisplayText: String {
        Self.normalizedDisplayText(text, to: displayLength)
    }
    private static func normalizedDisplayText(_ text: String, to length: Int) -> String {
        guard text.count < length else { return text }
        return text + String(repeating: " ", count: length - text.count)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SpecialTextView(
            "Preview Text",
            initialText: "Initial Text",
            replayTrigger: UUID(),
            animateOnAppear: false,
            configuration: .init(speed: 30)
        )
            .font(.system(size: 40, weight: .medium, design: .monospaced))
            .foregroundStyle(.white)
    }
}

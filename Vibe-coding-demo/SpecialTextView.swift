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
    let configuration: Configuration

    @State private var displayText: String
    @State private var currentPhase: Phase = .phase1
    @State private var animationStep = 0
    @State private var animationTask: Task<Void, Never>?

    init(
        _ text: String,
        configuration: Configuration = .default
    ) {
        self.text = text
        self.configuration = configuration
        _displayText = State(initialValue: String(repeating: " ", count: text.count))
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Reserve the final text block size so the animated layer does not
            // change layout while characters are shuffling.
            Text(text)
                .opacity(0)

            Text(displayText)
        }
            .onAppear {
                startAnimation()
            }
            .onDisappear {
                animationTask?.cancel()
                animationTask = nil
            }
            .onChange(of: text) { _, _ in
                startAnimation()
            }
            .onChange(of: configuration) { _, _ in
                startAnimation()
            }
    }

    private func startAnimation() {
        animationTask?.cancel()
        displayText = String(repeating: " ", count: text.count)
        currentPhase = .phase1
        animationStep = 0

        animationTask = Task {
            if configuration.delay > 0 {
                let delayNs = UInt64(configuration.delay * 1_000_000_000)
                try? await Task.sleep(nanoseconds: delayNs)
            }

            guard !Task.isCancelled else { return }

            while !Task.isCancelled {
                await MainActor.run {
                    switch currentPhase {
                    case .phase1:
                        runPhase1()
                    case .phase2:
                        runPhase2()
                    }
                }

                if displayText == text {
                    break
                }

                try? await Task.sleep(nanoseconds: configuration.speed * 1_000_000)
            }
        }
    }

    private func runPhase1() {
        let maxSteps = max(text.count * max(configuration.phaseOneCycles, 1), 1)
        let characters = Array(text)

        var chars: [Character] = []
        chars.reserveCapacity(text.count)

        for index in 0..<characters.count {
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
        let characters = Array(text)
        let framesPerCharacter = max(configuration.phaseTwoFramesPerCharacter, 1)
        let revealedCount = animationStep / framesPerCharacter

        var chars: [Character] = []
        chars.reserveCapacity(text.count)

        for index in 0..<min(revealedCount, characters.count) {
            chars.append(characters[index])
        }

        if revealedCount < characters.count {
            let cursor = cursorCharacter
            chars.append(animationStep.isMultiple(of: framesPerCharacter) ? cursor : randomChar(previous: nil))
        }

        while chars.count < characters.count {
            chars.append(randomChar(previous: chars.last))
        }

        displayText = String(chars)

        if animationStep < characters.count * framesPerCharacter - 1 {
            animationStep += 1
        } else {
            displayText = text
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
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SpecialTextView(
            "Preview Text",
            configuration: .init(speed: 30)
        )
            .font(.system(size: 40, weight: .medium, design: .monospaced))
            .foregroundStyle(.white)
    }
}

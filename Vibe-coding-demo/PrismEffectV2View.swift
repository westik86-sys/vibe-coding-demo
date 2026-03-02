import SwiftUI

struct PrismEffectV2View: View {
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

    private var dynamicSampleOffset: CGFloat {
        CGFloat(max(lensAmount + abs(rippleAmount) + chromaticBase + chromaticWave, 120))
    }

    var body: some View {
        TimelineView(.animation) { context in
            let t = Float(context.date.timeIntervalSinceReferenceDate)

            ZStack {
                Color.black.ignoresSafeArea()

                Text("""
                Hello, world! Hello,
                world! Hello, world!
                Hello, world! Hello,
                world! Hello, world!
                Hello, world! Hello,
                world! Hello, world!
                Hello, world! Hello,
                world! Hello, world!
                """)
                .font(.system(size: 34, weight: .bold, design: .rounded))
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

import SwiftUI

struct ContentView: View {
    @State private var touch: CGPoint = .init(x: -10_000, y: -10_000)
    @State private var intensity: CGFloat = 0

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
            // Эффект “как на видео”: ripple + prism
            .layerEffect(
                ShaderLibrary.prismRipple(
                    .float2(Float(touch.x), Float(touch.y)),
                    .float(Float(intensity)),
                    .float(t)
                ),
                // на видео смещение заметное, поэтому offset нужен побольше
                maxSampleOffset: CGSize(width: 120, height: 120),
                isEnabled: intensity > 0.001
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        touch = v.location
                        // “липкая” мгновенная сила, как в демо
                        intensity = 1
                    }
                    .onEnded { _ in
                        // быстрое затухание
                        withAnimation(.easeOut(duration: 0.25)) {
                            intensity = 0
                        }
                    }
            )
        }
    }
}

#Preview {
    ContentView()
}

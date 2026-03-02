import SwiftUI

struct PrismEffectView: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Circle()
                .fill(
                    AngularGradient(
                        colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
                        center: .center
                    )
                )
                .blur(radius: 48)
                .scaleEffect(1.2)
                .rotationEffect(.degrees(rotation))
                .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: rotation)

            VStack(spacing: 10) {
                Text("Prism-Effect")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Animated rainbow prism glow")
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .onAppear {
            rotation = 360
        }
        .navigationTitle("Prism-Effect")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PrismEffectView()
}

import SwiftUI
import UIKit

struct EnvelopeView: View {
    @State private var progress: CGFloat = 0
    @State private var dragStartProgress: CGFloat = 0
    @State private var isDragging = false
    @State private var wasOpen = false

    var body: some View {
        ZStack {
            Color(white: 0.97)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 96)

                EnvelopeScene(progress: progress)
                    .frame(height: 470)
                    .padding(.horizontal, 24)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 12)
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    dragStartProgress = progress
                                }
                                let delta = -value.translation.height / 220
                                progress = min(1, max(0, dragStartProgress + delta))
                            }
                            .onEnded { _ in
                                let shouldOpen = progress >= 0.45
                                withAnimation(.easeOut(duration: 0.24)) {
                                    progress = shouldOpen ? 1 : 0
                                }
                                isDragging = false
                            }
                    )
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.24)) {
                            progress = progress < 0.5 ? 1 : 0
                        }
                    }

                VStack(spacing: 8) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(Color(.systemGray))
                        .opacity(Double(max(0, 1 - progress * 0.85)))
                    Text("Потяните вверх, чтобы открыть")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(.systemGray))
                        .opacity(Double(max(0, 1 - progress * 0.85)))
                }
                .padding(.top, 56)

                Spacer(minLength: 60)
            }
        }
        .onChange(of: progress) { value in
            let isOpenNow = value >= 0.9
            let isClosedNow = value <= 0.1

            if !wasOpen && isOpenNow {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
                wasOpen = true
            } else if wasOpen && isClosedNow {
                let generator = UIImpactFeedbackGenerator(style: .rigid)
                generator.prepare()
                generator.impactOccurred()
                wasOpen = false
            }
        }
    }
}

private struct EnvelopeScene: View {
    let progress: CGFloat

    private let panelSize: CGFloat = 292

    var body: some View {
        let p = progress
        let hingeY: CGFloat = 96
        let cardMaskHeight = panelSize * (0.58 + 0.44 * p)
        let cardMaskOffsetY = hingeY + panelSize * (0.28 - 0.18 * p)

        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.black.opacity(0.1))
                .blur(radius: 18)
                .frame(width: panelSize - 20, height: 18)
                .offset(y: 236)

            ZStack(alignment: .top) {
                // Bottom square (same size as flap)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.91), Color(white: 0.96)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: panelSize, height: panelSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.black.opacity(0.03), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
                    .offset(y: hingeY)

                // Card in bottom pocket
                CardView()
                    .frame(width: panelSize - 20, height: 146)
                    .offset(y: hingeY + 118 - 40 * p)
                    .mask(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .frame(width: panelSize - 10, height: cardMaskHeight)
                            .offset(y: cardMaskOffsetY)
                    )

                // Top square flap (same size as bottom part)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.80), Color(white: 0.88)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(white: 0.91), Color(white: 0.96)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .opacity(Double(p))
                    }
                    .frame(width: panelSize, height: panelSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.black.opacity(0.03), lineWidth: 1)
                    )
                    .rotation3DEffect(
                        .degrees(-172 * Double(p)),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .top,
                        perspective: 0.02
                    )
                    .offset(y: hingeY)
            }
            .frame(width: panelSize, height: 470)
        }
    }
}

private struct CardView: View {
    var body: some View {
        Image("EnvelopeCardImage")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.16), radius: 9, x: 0, y: 6)
    }
}

#Preview {
    NavigationStack {
        EnvelopeView()
    }
}

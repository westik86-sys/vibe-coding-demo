import SwiftUI

struct ShadersView: View {
    @Binding var path: NavigationPath

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 100)

            Color.black
                .layerEffect(
                    ShaderLibrary.noisyGradient(.boundingRect, .float(time)),
                    maxSampleOffset: .zero
                )
                .ignoresSafeArea()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Gradient") {
                        path.removeLast(path.count)
                        path.append(AppRoute.shadersGradient)
                    }
                    Button("Playground") {
                        path.removeLast(path.count)
                        path.append(AppRoute.shadersPlayground)
                    }
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

#Preview {
    ShadersPreviewHost()
}

#if DEBUG
private struct ShadersPreviewHost: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ShadersView(path: $path)
        }
    }
}
#endif

import SwiftUI

struct ShadersPlaygroundView: View {
    @Binding var path: NavigationPath

    var body: some View {
        List {
            Section("Basic Shader") {
                NavigationLink {
                    PlaygroundWaveView()
                } label: {
                    Text("Wave")
                }

                NavigationLink {
                    PlaygroundColorFilterView()
                } label: {
                    Text("Color Filter")
                }

                NavigationLink {
                    PlaygroundDistortionView()
                } label: {
                    Text("Distortion")
                }

                NavigationLink {
                    PlaygroundZoomView()
                } label: {
                    Text("Zoom")
                }
            }

            Section("WWDC Apple") {
                NavigationLink {
                    PlaygroundRippleView()
                } label: {
                    Text("Ripple")
                }
            }
        }
        .listStyle(.insetGrouped)
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

struct PlaygroundWaveView: View {
    @State private var progress: CGFloat = 1.0

    var body: some View {
        VStack {
            Image("sample")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .layerEffect(
                    ShaderLibrary.msl(.float(progress)),
                    maxSampleOffset: CGSize(width: 200, height: 200)
                )

            Slider(value: $progress, in: 0...10)
        }
        .navigationTitle("Wave")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

struct PlaygroundColorFilterView: View {
    @State private var progress: CGFloat = 0.0

    var body: some View {
        VStack {
            Image("sample")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .layerEffect(ShaderLibrary.colorfilter(.float(progress)), maxSampleOffset: .zero)

            Slider(value: $progress, in: 0...1)
        }
        .navigationTitle("Color Filter")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

struct PlaygroundDistortionView: View {
    @State private var progress: CGFloat = 0.0

    var body: some View {
        VStack {
            Image("sample")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .layerEffect(
                    ShaderLibrary.distortion(.float(progress), .boundingRect),
                    maxSampleOffset: CGSize(width: 0, height: 200)
                )

            Slider(value: $progress, in: 0...1)
        }
        .navigationTitle("Distortion")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            withAnimation(.spring()) {
                progress = 1.0
            }
        }
        .padding()
    }
}

struct PlaygroundZoomView: View {
    @State private var dragPoint: CGPoint = .zero
    @State private var progress: CGFloat = 0

    var body: some View {
        VStack {
            Image("sample")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .layerEffect(
                    ShaderLibrary.zoom(.boundingRect, .float2(dragPoint), .float(progress)),
                    maxSampleOffset: .zero
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragPoint = value.location
                            withAnimation(.smooth) {
                                progress = 1
                            }
                        }
                        .onEnded { _ in
                            dragPoint = .zero
                            withAnimation(.smooth) {
                                progress = 0
                            }
                        }
                )
        }
        .navigationTitle("Zoom")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

struct PlaygroundRippleView: View {
    @State private var originPoint: CGPoint = .zero
    @State private var time: CGFloat = 0
    @State private var amplitude: CGFloat = 12
    @State private var frequency: CGFloat = 15
    @State private var decay: CGFloat = 8
    @State private var speed: CGFloat = 1200

    var body: some View {
        VStack {
            Image("sample")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .layerEffect(
                    ShaderLibrary.Ripple(
                        .float2(originPoint),
                        .float(time),
                        .float(amplitude),
                        .float(frequency),
                        .float(decay),
                        .float(speed)
                    ),
                    maxSampleOffset: .zero
                )
                .onTapGesture { location in
                    originPoint = location
                    time = 0
                    withAnimation(.easeInOut(duration: 2)) {
                        time = 1
                    }
                }

            Text("Tap anywhere")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .navigationTitle("Ripple")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

#Preview {
    ShadersPlaygroundPreviewHost()
}

#if DEBUG
private struct ShadersPlaygroundPreviewHost: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ShadersPlaygroundView(path: $path)
        }
    }
}
#endif

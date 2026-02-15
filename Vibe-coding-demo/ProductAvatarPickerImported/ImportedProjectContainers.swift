import SwiftUI

struct CharityProjectContainerView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            CharityView(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .charityV1:
                        CharityView(path: $path)
                    case .charityV2:
                        CharityViewV2(path: $path)
                    case .shadersGradient, .shadersPlayground:
                        EmptyView()
                    }
                }
        }
    }
}

struct CharityV2ProjectContainerView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            CharityViewV2(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .charityV1:
                        CharityView(path: $path)
                    case .charityV2:
                        CharityViewV2(path: $path)
                    case .shadersGradient, .shadersPlayground:
                        EmptyView()
                    }
                }
        }
    }
}

struct ShadersProjectContainerView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ShadersView(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .shadersGradient:
                        ShadersView(path: $path)
                    case .shadersPlayground:
                        ShadersPlaygroundView(path: $path)
                    case .charityV1, .charityV2:
                        EmptyView()
                    }
                }
        }
    }
}

struct ShadersPlaygroundProjectContainerView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ShadersPlaygroundView(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .shadersGradient:
                        ShadersView(path: $path)
                    case .shadersPlayground:
                        ShadersPlaygroundView(path: $path)
                    case .charityV1, .charityV2:
                        EmptyView()
                    }
                }
        }
    }
}

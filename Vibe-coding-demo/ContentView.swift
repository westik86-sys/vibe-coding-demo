import SwiftUI

struct ContentView: View {
    @State private var path: [AppProject] = []

    var body: some View {
        NavigationStack(path: $path) {
            List(AppProject.allCases) { project in
                Button {
                    path.append(project)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.title)
                            .font(.headline)
                        Text(project.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Showcase App")
            .navigationDestination(for: AppProject.self) { project in
                switch project {
                case .particleEffectPocMain:
                    ParticleEffectPocMainView()
                case .charity:
                    CharityStandaloneContainerView()
                case .report:
                    ReportLaunchView()
                case .avatarSettings:
                    ProductAvatarView()
                case .notificationCenter:
                    NotificationCenterView()
                case .notificationCenterPulseLike:
                    PulseLikeNotificationCenterView()
                case .ncInap:
                    NCInAppView()
                case .envelope:
                    EnvelopeView()
                case .pullToRefresh:
                    PullToRefreshView()
                case .pullToRefreshUIKit:
                    PullToRefreshUIKitView()

                // IMPORTANT: When you add Project 2 to AppProject,
                // also add its destination here:
                // case .project2:
                //     Project2View()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

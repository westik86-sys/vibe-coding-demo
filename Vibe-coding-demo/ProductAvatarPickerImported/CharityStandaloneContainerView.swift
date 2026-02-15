import SwiftUI

struct CharityStandaloneContainerView: View {
    @State private var path = NavigationPath()

    var body: some View {
        CharityView(path: $path)
    }
}


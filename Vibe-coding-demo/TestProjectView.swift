import SwiftUI

struct TestProjectView: View {
    var body: some View {
        ZStack {
            Color.blue.opacity(0.2)
                .ignoresSafeArea()

            Text("Hello Test")
                .font(.largeTitle.bold())
                .foregroundStyle(.blue)
        }
        .navigationTitle("Test Project")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TestProjectView()
    }
}

import SwiftUI

struct FrostUIView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Ты пидор")
                    .font(.custom("Inter-Regular", size: 64))
                    .multilineTextAlignment(.center)

                Text("🤡")
                    .font(.system(size: 64))
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
        }
        .navigationTitle("FrostUI")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FrostUIView()
    }
}

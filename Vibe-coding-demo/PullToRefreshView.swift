import SwiftUI

struct PullToRefreshView: View {
    @State private var lastRefreshTime = Date()

    var body: some View {
        List {
            Text("Потяни вниз для обновления")
                .font(.headline)
            
            Text("Последнее обновление:")
            Text(lastRefreshTime.formatted(date: .omitted, time: .standard))
                .foregroundColor(.secondary)
        }
        .refreshable {
            await performRefresh()
        }
    }

    func performRefresh() async {
        // Имитация загрузки данных
        try? await Task.sleep(for: .seconds(2))
        
        // Обновление времени
        lastRefreshTime = Date()
    }
}

#Preview {
    NavigationStack {
        PullToRefreshView()
    }
}

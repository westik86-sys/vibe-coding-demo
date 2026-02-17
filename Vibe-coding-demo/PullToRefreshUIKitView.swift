import SwiftUI
import UIKit

struct PullToRefreshUIKitView: View {
    var body: some View {
        PullToRefreshUIKitContainer()
            .navigationTitle("Pull to Refresh (UIKit)")
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PullToRefreshUIKitContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PullToRefreshTableViewController {
        PullToRefreshTableViewController()
    }

    func updateUIViewController(_ uiViewController: PullToRefreshTableViewController, context: Context) {}
}

private final class PullToRefreshTableViewController: UITableViewController {
    private var lastRefreshTime = Date()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        self.refreshControl = refreshControl
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = UIListContentConfiguration.valueCell()

        switch indexPath.row {
        case 0:
            content.text = "Потяни вниз для обновления"
        case 1:
            content.text = "Последнее обновление:"
        default:
            content.text = lastRefreshTime.formatted(date: .omitted, time: .standard)
            content.secondaryText = "Обновляется через UIRefreshControl"
        }

        cell.contentConfiguration = content
        cell.selectionStyle = .none
        return cell
    }

    @objc private func handleRefresh() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            lastRefreshTime = Date()
            tableView.reloadData()
            refreshControl?.endRefreshing()
        }
    }
}

#Preview {
    NavigationStack {
        PullToRefreshUIKitView()
    }
}

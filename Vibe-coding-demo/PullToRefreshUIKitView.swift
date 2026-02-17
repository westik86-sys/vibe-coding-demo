import SwiftUI
import UIKit
import RefreshControlKit

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
    private let refreshControlKit = RefreshControl(view: PullToRefreshIndicatorView())

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.addRefreshControl(refreshControlKit)
        refreshControlKit.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
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
            refreshControlKit.endRefreshing()
        }
    }
}

private final class PullToRefreshIndicatorView: UIView, RefreshControlView {
    private static let controlHeight: CGFloat = 64

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "🤡"
        label.font = .systemFont(ofSize: 26)
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Потяни для обновления"
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .caption1)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: Self.controlHeight)))
        let stack = UIStackView(arrangedSubviews: [emojiLabel, titleLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 10),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.controlHeight)
    }

    func didScroll(_ progress: RefreshControl.Progress) {
        emojiLabel.transform = CGAffineTransform(rotationAngle: progress.value * .pi * 2)
    }

    func willRefresh() {
        titleLabel.text = "Обновляем..."
    }

    func didRefresh() {
        titleLabel.text = "Потяни для обновления"
        emojiLabel.transform = .identity
    }
}

#Preview {
    NavigationStack {
        PullToRefreshUIKitView()
    }
}

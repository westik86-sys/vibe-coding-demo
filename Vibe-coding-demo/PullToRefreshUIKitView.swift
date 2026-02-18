import SwiftUI
import UIKit
import RefreshControlKit
import Lottie

struct PullToRefreshUIKitView: View {
    @State private var settings = PullToRefreshSettingsStorage.load()
    @State private var isShowingSettings = false

    var body: some View {
        PullToRefreshUIKitContainer(settings: settings)
            .navigationTitle("Pull to Refresh (UIKit)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Label("Settings", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                PullToRefreshSettingsView(settings: $settings)
            }
            .onChange(of: settings) { newValue in
                PullToRefreshSettingsStorage.save(newValue)
            }
    }
}

private struct PullToRefreshUIKitContainer: UIViewControllerRepresentable {
    let settings: PullToRefreshSettings

    func makeUIViewController(context: Context) -> PullToRefreshTableViewController {
        PullToRefreshTableViewController(settings: settings)
    }

    func updateUIViewController(_ uiViewController: PullToRefreshTableViewController, context: Context) {
        uiViewController.apply(settings: settings)
    }
}

private final class PullToRefreshTableViewController: UITableViewController {
    private var lastRefreshTime = Date()
    private var settings: PullToRefreshSettings
    private var refreshControlKit: RefreshControl?

    init(settings: PullToRefreshSettings) {
        self.settings = settings
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        rebuildRefreshControl()
    }

    func apply(settings newSettings: PullToRefreshSettings) {
        guard settings != newSettings else { return }
        settings = newSettings
        rebuildRefreshControl()
        tableView.reloadData()
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
            content.secondaryText = "Задержка: \(settings.refreshDuration.formatted(.number.precision(.fractionLength(0...1)))) c"
        }

        cell.contentConfiguration = content
        cell.selectionStyle = .none
        return cell
    }

    @objc private func handleRefresh() {
        Task { @MainActor in
            let delay = max(settings.refreshDuration, 0)
            try? await Task.sleep(for: .seconds(delay))
            lastRefreshTime = Date()
            tableView.reloadData()
            refreshControlKit?.endRefreshing()
        }
    }

    private func rebuildRefreshControl() {
        refreshControlKit?.removeTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        refreshControlKit?.removeFromSuperview()

        let indicator = PullToRefreshIndicatorView(settings: settings)
        let control = RefreshControl(view: indicator, configuration: settings.refreshConfiguration)
        tableView.addRefreshControl(control)
        control.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)

        refreshControlKit = control
    }
}

private struct PullToRefreshSettingsView: View {
    @Binding var settings: PullToRefreshSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("RefreshControlKit") {
                    Picker("Layout", selection: $settings.layout) {
                        ForEach(PullToRefreshSettings.LayoutOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Trigger event", selection: $settings.triggerEvent) {
                        ForEach(PullToRefreshSettings.TriggerEventOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Custom trigger height", isOn: $settings.useCustomTriggerHeight)
                    if settings.useCustomTriggerHeight {
                        Slider(value: $settings.triggerHeight, in: 24 ... 180, step: 1)
                        Text("Trigger height: \(Int(settings.triggerHeight)) pt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Refresh") {
                    Slider(value: $settings.refreshDuration, in: 0 ... 5, step: 0.1)
                    Text("Duration: \(settings.refreshDuration.formatted(.number.precision(.fractionLength(1)))) s")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Indicator") {
                    Slider(value: $settings.indicatorHeight, in: 40 ... 140, step: 1)
                    Text("Height: \(Int(settings.indicatorHeight)) pt")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(value: $settings.animationSize, in: 16 ... 88, step: 1)
                    Text("Animation size: \(Int(settings.animationSize)) pt")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(value: $settings.horizontalSpacing, in: 0 ... 24, step: 1)
                    Text("Spacing: \(Int(settings.horizontalSpacing)) pt")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(value: $settings.verticalInset, in: 0 ... 24, step: 1)
                    Text("Vertical inset: \(Int(settings.verticalInset)) pt")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Loop mode", selection: $settings.loopMode) {
                        ForEach(PullToRefreshSettings.LoopModeOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Scrub with pull", isOn: $settings.scrubWithPull)
                    Toggle("Show status text", isOn: $settings.showStatusText)

                    if settings.showStatusText {
                        TextField("Status text", text: $settings.statusText)
                    }
                }

                Section {
                    Button("Reset to defaults", role: .destructive) {
                        settings = PullToRefreshSettings()
                    }
                }
            }
            .navigationTitle("Pull-to-Refresh Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct PullToRefreshSettings: Equatable, Codable {
    enum LayoutOption: String, CaseIterable, Identifiable, Codable {
        case top
        case bottom

        var id: String { rawValue }

        var title: String {
            switch self {
            case .top:
                return "Top"
            case .bottom:
                return "Bottom"
            }
        }

        var refreshLayout: RefreshControl.Configuration.Layout {
            switch self {
            case .top:
                return .top
            case .bottom:
                return .bottom
            }
        }
    }

    enum TriggerEventOption: String, CaseIterable, Identifiable, Codable {
        case dragging
        case released

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dragging:
                return "Dragging"
            case .released:
                return "Released"
            }
        }

        var refreshEvent: RefreshControl.Configuration.Trigger.Event {
            switch self {
            case .dragging:
                return .dragging
            case .released:
                return .released
            }
        }
    }

    enum LoopModeOption: String, CaseIterable, Identifiable, Codable {
        case loop
        case playOnce

        var id: String { rawValue }

        var title: String {
            switch self {
            case .loop:
                return "Loop"
            case .playOnce:
                return "Play once"
            }
        }

        var lottieLoopMode: LottieLoopMode {
            switch self {
            case .loop:
                return .loop
            case .playOnce:
                return .playOnce
            }
        }
    }

    var layout: LayoutOption = .top
    var triggerEvent: TriggerEventOption = .dragging
    var useCustomTriggerHeight = false
    var triggerHeight: Double = 64
    var refreshDuration: Double = 0

    var indicatorHeight: Double = 64
    var animationSize: Double = 30
    var horizontalSpacing: Double = 8
    var verticalInset: Double = 10
    var scrubWithPull = true

    var showStatusText = true
    var statusText = "Обновляем..."
    var loopMode: LoopModeOption = .loop

    var refreshConfiguration: RefreshControl.Configuration {
        let height = useCustomTriggerHeight ? CGFloat(triggerHeight) : nil
        let trigger = RefreshControl.Configuration.Trigger(height: height, event: triggerEvent.refreshEvent)
        return RefreshControl.Configuration(layout: layout.refreshLayout, trigger: trigger)
    }
}

private enum PullToRefreshSettingsStorage {
    private static let key = "pullToRefreshUIKit.settings"

    static func load() -> PullToRefreshSettings {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let settings = try? JSONDecoder().decode(PullToRefreshSettings.self, from: data)
        else {
            return PullToRefreshSettings()
        }
        return settings
    }

    static func save(_ settings: PullToRefreshSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

private final class PullToRefreshIndicatorView: UIView, RefreshControlView {
    private var settings: PullToRefreshSettings {
        didSet {
            applySettings()
        }
    }

    private var isRefreshing = false
    private var animationSizeConstraint: NSLayoutConstraint?
    private var animationHeightConstraint: NSLayoutConstraint?
    private var stackTopConstraint: NSLayoutConstraint?
    private var stackBottomConstraint: NSLayoutConstraint?

    private let animationView: LottieAnimationView = {
        let view = LottieAnimationView()
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .pauseAndRestore
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .caption1)
        return label
    }()

    private let stack = UIStackView()

    init(settings: PullToRefreshSettings) {
        self.settings = settings
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: CGFloat(settings.indicatorHeight))))
        configureAnimation()
        configureLayout()
        applySettings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: CGFloat(settings.indicatorHeight))
    }

    func didScroll(_ progress: RefreshControl.Progress) {
        guard !isRefreshing, settings.scrubWithPull else { return }
        animationView.currentProgress = progress.value
    }

    func willRefresh() {
        isRefreshing = true
        animationView.currentProgress = 0
        animationView.play()
    }

    func didRefresh() {
        isRefreshing = false
        animationView.stop()
        animationView.currentProgress = 0
    }

    private func configureLayout() {
        stack.axis = .horizontal
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(animationView)
        stack.addArrangedSubview(titleLabel)

        animationView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        let sizeConstraint = animationView.widthAnchor.constraint(equalToConstant: CGFloat(settings.animationSize))
        let heightConstraint = animationView.heightAnchor.constraint(equalToConstant: CGFloat(settings.animationSize))
        animationSizeConstraint = sizeConstraint
        animationHeightConstraint = heightConstraint

        let topConstraint = stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: CGFloat(settings.verticalInset))
        let bottomConstraint = stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -CGFloat(settings.verticalInset))
        stackTopConstraint = topConstraint
        stackBottomConstraint = bottomConstraint

        NSLayoutConstraint.activate([
            sizeConstraint,
            heightConstraint,
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            topConstraint,
            bottomConstraint
        ])
    }

    private func applySettings() {
        animationView.loopMode = settings.loopMode.lottieLoopMode
        animationSizeConstraint?.constant = CGFloat(settings.animationSize)
        animationHeightConstraint?.constant = CGFloat(settings.animationSize)
        stack.spacing = CGFloat(settings.horizontalSpacing)
        stackTopConstraint?.constant = CGFloat(settings.verticalInset)
        stackBottomConstraint?.constant = -CGFloat(settings.verticalInset)

        titleLabel.text = settings.statusText
        titleLabel.isHidden = !settings.showStatusText

        invalidateIntrinsicContentSize()
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func configureAnimation() {
        guard
            let path = Bundle.main.path(forResource: "Coin without Glow", ofType: "json"),
            let animation = LottieAnimation.filepath(path)
        else {
            return
        }
        animationView.animation = animation
    }
}

#Preview {
    NavigationStack {
        PullToRefreshUIKitView()
    }
}

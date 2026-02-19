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
                Section("Presets") {
                    Picker("Preset", selection: $settings.selectedPreset) {
                        ForEach(PullToRefreshSettings.PresetOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("Preset 1 animation name", text: $settings.preset1AnimationName)
                    TextField("Preset 2 animation name", text: $settings.preset2AnimationName)
                    Text("Current animation: \(settings.activeAnimationName).json")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

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
                        SliderSettingRow(
                            title: "Trigger height",
                            value: $settings.triggerHeight,
                            range: 24 ... 180,
                            step: 1,
                            valueText: { "\(Int($0)) pt" }
                        )
                    }
                }

                Section("Refresh") {
                    SliderSettingRow(
                        title: "Duration",
                        value: $settings.refreshDuration,
                        range: 0 ... 5,
                        step: 0.1,
                        valueText: { $0.formatted(.number.precision(.fractionLength(1))) + " s" },
                        disabled: settings.selectedPreset == .preset1 || settings.selectedPreset == .preset2
                    )
                }

                Section("Indicator") {
                    SliderSettingRow(
                        title: "Height",
                        value: $settings.indicatorHeight,
                        range: 40 ... 140,
                        step: 1,
                        valueText: { "\(Int($0)) pt" },
                        disabled: settings.selectedPreset == .preset2
                    )

                    SliderSettingRow(
                        title: "Animation size",
                        value: $settings.animationSize,
                        range: 16 ... 88,
                        step: 1,
                        valueText: { "\(Int($0)) pt" },
                        disabled: settings.selectedPreset == .preset1 || settings.selectedPreset == .preset2
                    )

                    SliderSettingRow(
                        title: "Spacing",
                        value: $settings.horizontalSpacing,
                        range: 0 ... 24,
                        step: 1,
                        valueText: { "\(Int($0)) pt" },
                        disabled: settings.selectedPreset == .preset1
                    )

                    SliderSettingRow(
                        title: "Vertical inset",
                        value: $settings.verticalInset,
                        range: 0 ... 24,
                        step: 1,
                        valueText: { "\(Int($0)) pt" }
                    )

                    Picker("Loop mode", selection: $settings.loopMode) {
                        ForEach(PullToRefreshSettings.LoopModeOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Scrub with pull", isOn: $settings.scrubWithPull)
                    Toggle("Show status text", isOn: $settings.showStatusText)
                        .disabled(settings.selectedPreset == .preset2)

                    if settings.selectedPreset == .preset2 {
                        Text("Text is disabled for Preset 2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if settings.showStatusText {
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
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
            .onAppear {
                applyPresetConstraints()
            }
            .onChange(of: settings.selectedPreset) { _ in
                applyPresetConstraints()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func applyPresetConstraints() {
        switch settings.selectedPreset {
        case .preset1:
            settings.refreshDuration = 1.2
            settings.animationSize = 60
            settings.horizontalSpacing = 0
        case .preset2:
            settings.refreshDuration = 1.2
            settings.indicatorHeight = 140
            settings.animationSize = 88
            settings.showStatusText = false
        }
    }
}

private struct SliderSettingRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueText: (Double) -> String
    var disabled: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(valueText(value))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
                .disabled(disabled)
        }
        .listRowSeparator(.hidden)
    }
}

private struct PullToRefreshSettings: Equatable, Codable {
    enum PresetOption: String, CaseIterable, Identifiable, Codable {
        case preset1
        case preset2

        var id: String { rawValue }

        var title: String {
            switch self {
            case .preset1:
                return "Preset 1"
            case .preset2:
                return "Preset 2"
            }
        }
    }

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

    struct PresetConfig: Equatable, Codable {
        var animationName: String
        var layout: LayoutOption
        var triggerEvent: TriggerEventOption
        var useCustomTriggerHeight: Bool
        var triggerHeight: Double
        var refreshDuration: Double
        var indicatorHeight: Double
        var animationSize: Double
        var horizontalSpacing: Double
        var verticalInset: Double
        var scrubWithPull: Bool
        var showStatusText: Bool
        var statusText: String
        var loopMode: LoopModeOption

        static let preset1Default = PresetConfig(
            animationName: "Coin without Glow",
            layout: .top,
            triggerEvent: .dragging,
            useCustomTriggerHeight: false,
            triggerHeight: 64,
            refreshDuration: 1.2,
            indicatorHeight: 64,
            animationSize: 60,
            horizontalSpacing: 0,
            verticalInset: 10,
            scrubWithPull: true,
            showStatusText: true,
            statusText: "Обновляем...",
            loopMode: .loop
        )

        static let preset2Default = PresetConfig(
            animationName: "Dino Loading",
            layout: .top,
            triggerEvent: .dragging,
            useCustomTriggerHeight: false,
            triggerHeight: 64,
            refreshDuration: 0,
            indicatorHeight: 64,
            animationSize: 30,
            horizontalSpacing: 8,
            verticalInset: 10,
            scrubWithPull: true,
            showStatusText: true,
            statusText: "Обновляем...",
            loopMode: .loop
        )

    }

    var selectedPreset: PresetOption = .preset1
    var preset1: PresetConfig = .preset1Default
    var preset2: PresetConfig = .preset2Default

    private var activePresetConfig: PresetConfig {
        get {
            switch selectedPreset {
            case .preset1:
                return preset1
            case .preset2:
                return preset2
            }
        }
        set {
            switch selectedPreset {
            case .preset1:
                preset1 = newValue
            case .preset2:
                preset2 = newValue
            }
        }
    }

    var preset1AnimationName: String {
        get { preset1.animationName }
        set { preset1.animationName = newValue }
    }

    var preset2AnimationName: String {
        get { preset2.animationName }
        set { preset2.animationName = newValue }
    }

    var layout: LayoutOption {
        get { activePresetConfig.layout }
        set {
            var config = activePresetConfig
            config.layout = newValue
            activePresetConfig = config
        }
    }

    var triggerEvent: TriggerEventOption {
        get { activePresetConfig.triggerEvent }
        set {
            var config = activePresetConfig
            config.triggerEvent = newValue
            activePresetConfig = config
        }
    }

    var useCustomTriggerHeight: Bool {
        get { activePresetConfig.useCustomTriggerHeight }
        set {
            var config = activePresetConfig
            config.useCustomTriggerHeight = newValue
            activePresetConfig = config
        }
    }

    var triggerHeight: Double {
        get { activePresetConfig.triggerHeight }
        set {
            var config = activePresetConfig
            config.triggerHeight = newValue
            activePresetConfig = config
        }
    }

    var refreshDuration: Double {
        get { activePresetConfig.refreshDuration }
        set {
            var config = activePresetConfig
            config.refreshDuration = newValue
            activePresetConfig = config
        }
    }

    var indicatorHeight: Double {
        get { activePresetConfig.indicatorHeight }
        set {
            var config = activePresetConfig
            config.indicatorHeight = newValue
            activePresetConfig = config
        }
    }

    var animationSize: Double {
        get { activePresetConfig.animationSize }
        set {
            var config = activePresetConfig
            config.animationSize = newValue
            activePresetConfig = config
        }
    }

    var horizontalSpacing: Double {
        get { activePresetConfig.horizontalSpacing }
        set {
            var config = activePresetConfig
            config.horizontalSpacing = newValue
            activePresetConfig = config
        }
    }

    var verticalInset: Double {
        get { activePresetConfig.verticalInset }
        set {
            var config = activePresetConfig
            config.verticalInset = newValue
            activePresetConfig = config
        }
    }

    var scrubWithPull: Bool {
        get { activePresetConfig.scrubWithPull }
        set {
            var config = activePresetConfig
            config.scrubWithPull = newValue
            activePresetConfig = config
        }
    }

    var showStatusText: Bool {
        get { activePresetConfig.showStatusText }
        set {
            var config = activePresetConfig
            config.showStatusText = newValue
            activePresetConfig = config
        }
    }

    var statusText: String {
        get { activePresetConfig.statusText }
        set {
            var config = activePresetConfig
            config.statusText = newValue
            activePresetConfig = config
        }
    }

    var loopMode: LoopModeOption {
        get { activePresetConfig.loopMode }
        set {
            var config = activePresetConfig
            config.loopMode = newValue
            activePresetConfig = config
        }
    }

    var activeAnimationName: String {
        let rawName = activePresetConfig.animationName
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Coin without Glow"
        }
        if trimmed.lowercased().hasSuffix(".json") {
            return String(trimmed.dropLast(5))
        }
        return trimmed
    }

    var refreshConfiguration: RefreshControl.Configuration {
        let height = useCustomTriggerHeight ? CGFloat(triggerHeight) : nil
        let trigger = RefreshControl.Configuration.Trigger(height: height, event: triggerEvent.refreshEvent)
        return RefreshControl.Configuration(layout: layout.refreshLayout, trigger: trigger)
    }
}

private enum PullToRefreshSettingsStorage {
    private static let key = "pullToRefreshUIKit.settings"

    static func load() -> PullToRefreshSettings {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return PullToRefreshSettings()
        }

        if let settings = try? JSONDecoder().decode(PullToRefreshSettings.self, from: data) {
            return settings
        }

        // Backward compatibility for older flat settings model.
        if let legacy = try? JSONDecoder().decode(LegacyPullToRefreshSettings.self, from: data) {
            var migrated = PullToRefreshSettings()
            migrated.selectedPreset = legacy.selectedPreset
            migrated.preset1.animationName = legacy.preset1AnimationName
            migrated.preset2.animationName = legacy.preset2AnimationName == "Coin without Glow" ? "Dino Loading" : legacy.preset2AnimationName

            let legacyConfig = PullToRefreshSettings.PresetConfig(
                animationName: legacy.selectedPreset == .preset1 ? legacy.preset1AnimationName : migrated.preset2.animationName,
                layout: legacy.layout,
                triggerEvent: legacy.triggerEvent,
                useCustomTriggerHeight: legacy.useCustomTriggerHeight,
                triggerHeight: legacy.triggerHeight,
                refreshDuration: legacy.refreshDuration,
                indicatorHeight: legacy.indicatorHeight,
                animationSize: legacy.animationSize,
                horizontalSpacing: legacy.horizontalSpacing,
                verticalInset: legacy.verticalInset,
                scrubWithPull: legacy.scrubWithPull,
                showStatusText: legacy.showStatusText,
                statusText: legacy.statusText,
                loopMode: legacy.loopMode
            )

            switch legacy.selectedPreset {
            case .preset1:
                migrated.preset1 = legacyConfig
            case .preset2:
                migrated.preset2 = legacyConfig
            }
            return migrated
        }

        return PullToRefreshSettings()
    }

    static func save(_ settings: PullToRefreshSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

private struct LegacyPullToRefreshSettings: Codable {
    var layout: PullToRefreshSettings.LayoutOption = .top
    var selectedPreset: PullToRefreshSettings.PresetOption = .preset1
    var preset1AnimationName = "Coin without Glow"
    var preset2AnimationName = "Dino Loading"
    var triggerEvent: PullToRefreshSettings.TriggerEventOption = .dragging
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
    var loopMode: PullToRefreshSettings.LoopModeOption = .loop
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
        configureAnimation()

        invalidateIntrinsicContentSize()
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func configureAnimation() {
        guard
            let path = Bundle.main.path(forResource: settings.activeAnimationName, ofType: "json"),
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

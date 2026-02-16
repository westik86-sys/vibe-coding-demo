import SwiftUI
import PhotosUI
import Photos
import UIKit
import UniformTypeIdentifiers
import PencilKit
import OSLog

private let reportTapLogger = Logger(subsystem: "ProductAvatarPicker", category: "ReportTap")

struct ReportLaunchView: View {
    @State private var isReportFlowPresented = false
    @State private var capturedScreenshot: UIImage?
    @State private var isResolvingScreenshot = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            Image(colorScheme == .dark ? "ReportDark" : "ReportLight")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            VStack {
                if isResolvingScreenshot {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white.opacity(0.9))
                        .padding(.top, 160)
                }

                Spacer()

                Button {
                    guard capturedScreenshot != nil else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.95)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                        isReportFlowPresented = true
                    }
                } label: {
                    Text("На проде замечено 💩")
                        .font(.system(size: 45 * 0.36, weight: .regular))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 22)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color(red: 71 / 255, green: 142 / 255, blue: 249 / 255))
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
                .padding(.bottom, 78)
                .opacity(capturedScreenshot == nil ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: capturedScreenshot != nil)
            }
        }
        .navigationTitle("Report")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            guard !isResolvingScreenshot else { return }
            Task { @MainActor in
                await resolveCapturedScreenshot()
            }
        }
        .navigationDestination(isPresented: $isReportFlowPresented) {
            ReportView(initialScreenshots: capturedScreenshot.map { [$0] } ?? [])
        }
    }

    @MainActor
    private func resolveCapturedScreenshot() async {
        isResolvingScreenshot = true
        defer { isResolvingScreenshot = false }

        let triggerTime = Date()
        let minDate = triggerTime.addingTimeInterval(-2)

        if let image = await fetchLatestScreenshot(after: minDate) {
            capturedScreenshot = image
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.8)
            return
        }

        if let image = await fetchLatestScreenshot(after: .distantPast) {
            capturedScreenshot = image
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.8)
        }
    }

    private func fetchLatestScreenshot(after minDate: Date) async -> UIImage? {
        guard await ensurePhotosReadAccess() else { return nil }

        for _ in 0..<6 {
            if let image = await loadLatestScreenshotFromLibrary(minDate: minDate) {
                return image
            }
            try? await Task.sleep(nanoseconds: 120_000_000)
        }
        return nil
    }

    private func ensurePhotosReadAccess() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let requestedStatus = await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                    continuation.resume(returning: newStatus)
                }
            }
            return requestedStatus == .authorized || requestedStatus == .limited
        default:
            return false
        }
    }

    private func loadLatestScreenshotFromLibrary(minDate: Date) async -> UIImage? {
        let options = PHFetchOptions()
        options.fetchLimit = 30
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(
            format: "(mediaSubtype & %d) != 0",
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )

        let assets = PHAsset.fetchAssets(with: .image, options: options)
        guard assets.count > 0 else { return nil }

        var targetAsset: PHAsset?
        assets.enumerateObjects { asset, _, stop in
            guard let creationDate = asset.creationDate else { return }
            if creationDate >= minDate {
                targetAsset = asset
                stop.pointee = true
            }
        }

        guard let targetAsset else { return nil }
        return await image(for: targetAsset)
    }

    private func image(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .none
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                guard let data, let image = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }
}

struct ReportView: View {
    @State private var screenshotPickerItems: [PhotosPickerItem] = []
    @State private var screenshots: [ReportScreenshot]
    @State private var processedPhotoItemIdentifiers: Set<String> = []
    @State private var activeScreenshotID: UUID?
    @State private var selectedMarkupTarget: ReportMarkupEditingTarget?
    @State private var isMarkupEditorPresented: Bool = false
    @State private var reportText: String = ""
    @State private var isAttachmentPhotoPickerPresented: Bool = false
    @State private var isAttachmentFilePickerPresented: Bool = false
    @State private var isComposerEditing: Bool = false
    @State private var keyboardTopInScreen: CGFloat = UIScreen.main.bounds.height
    @State private var composerFrameInScreen: CGRect?
    @State private var frameTransitionProgress: CGFloat = 0
    @State private var isShowingSubmitSuccess: Bool = false
    @State private var isThankYouVisible: Bool = false
    @State private var isBatchAddingScreenshots: Bool = false
    @State private var hasOpenedMarkupEditor: Bool = false
    @State private var hasCompletedDrawingOnboarding: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    init(initialScreenshots: [UIImage] = []) {
        _screenshots = State(initialValue: initialScreenshots.map { ReportScreenshot(image: $0) })
    }

    private var orderedScreenshots: [ReportScreenshot] {
        screenshots.reversed()
    }

    private var onboardingTargetID: UUID? {
        activeScreenshotID ?? screenshots.last?.id
    }

    private var shouldShowDrawingOnboarding: Bool {
        !screenshots.isEmpty &&
        !isComposerEditing &&
        !isShowingSubmitSuccess &&
        !hasOpenedMarkupEditor &&
        !hasCompletedDrawingOnboarding
    }

    var body: some View {
        GeometryReader { proxy in
            let baseCardWidth = 226.0
            let baseCardHeight = 489.0
            let cardAspectRatio = baseCardWidth / baseCardHeight
            let proxyGlobalMinY = proxy.frame(in: .global).minY
            let topSpacingExpanded: CGFloat = 32.0
            let topSpacingCompact: CGFloat = 8.0
            let noteTopSpacing: CGFloat = 36.0
            let noteBottomSpacing: CGFloat = 36.0
            let noteTextHeight: CGFloat = 22.0
            let inputHeight: CGFloat = 44.0
            let inputKeyboardGap: CGFloat = 8.0
            let cardToInputGap: CGFloat = 20.0
            let keyboardTopLocal = max(0, min(proxy.size.height, keyboardTopInScreen - proxyGlobalMinY))
            let composerTopLocal = composerFrameInScreen.map { $0.minY - proxyGlobalMinY }
            let estimatedInputTopLocal: CGFloat = keyboardTopLocal - inputKeyboardGap - inputHeight
            let inputTopLocal: CGFloat = {
                if frameTransitionProgress > 0.001 || isComposerEditing {
                    return composerTopLocal ?? estimatedInputTopLocal
                }
                return estimatedInputTopLocal
            }()
            let topSpacing = lerp(topSpacingExpanded, topSpacingCompact, t: frameTransitionProgress)
            let reservedExpanded: CGFloat = noteTopSpacing + noteTextHeight + noteBottomSpacing
            let reservedBelowCard = lerp(reservedExpanded, cardToInputGap, t: frameTransitionProgress)
            let availableCardHeight = inputTopLocal - reservedBelowCard - topSpacing
            let maxAllowedCardWidth = max(1, proxy.size.width - 32)
            let noteCollapseProgress = smoothStep(frameTransitionProgress)
            let noteFadeOutProgress = smoothStep(min(1, frameTransitionProgress / 0.42))
            let noteOpacity = max(0, 1 - noteFadeOutProgress)
            let noteTopAnimated = noteTopSpacing * (1 - noteCollapseProgress)
            let noteHeightAnimated = noteTextHeight * (1 - noteCollapseProgress)
            let noteBottomAnimated = noteBottomSpacing * (1 - noteCollapseProgress)
            let dynamicHeight = max(1, availableCardHeight)
            let heightScale = dynamicHeight / baseCardHeight
            let widthScale = maxAllowedCardWidth / baseCardWidth
            let cardScale = max(0.05, min(heightScale, widthScale))
            let contentScale = min(1, cardScale)
            let cardSize = CGSize(
                width: baseCardWidth * cardScale,
                height: baseCardHeight * cardScale
            )
            let scaledCornerRadius = 24 * cardScale
            let cardBorderColor: Color = colorScheme == .dark
                ? Color.white.opacity(0.10)
                : Color(red: 0 / 255, green: 16 / 255, blue: 36 / 255).opacity(0.12)
            let carouselHorizontalInset = max(0, (proxy.size.width - cardSize.width) / 2)

            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea(.container, edges: .all)
                    .onTapGesture {
                        reportTapLogger.debug("background tap editing=\(self.isComposerEditing, privacy: .public)")
                        dismissKeyboardIfNeeded()
                    }

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: max(0, inputTopLocal))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            reportTapLogger.debug("top area tap editing=\(self.isComposerEditing, privacy: .public)")
                            dismissKeyboardIfNeeded()
                        }
                    Spacer(minLength: 0)
                }
                .allowsHitTesting(isComposerEditing)

                VStack(spacing: 0) {
                    Group {
                        if orderedScreenshots.isEmpty {
                            PhotosPicker(selection: $screenshotPickerItems, maxSelectionCount: 0, matching: .images) {
                                reportScreenshotCard(
                                    image: nil,
                                    cardSize: cardSize,
                                    cornerRadius: scaledCornerRadius,
                                    borderColor: cardBorderColor,
                                    contentScale: contentScale
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(orderedScreenshots) { screenshot in
                                        ZStack(alignment: .topTrailing) {
                                            reportScreenshotCard(
                                                image: screenshot.image,
                                                cardSize: cardSize,
                                                cornerRadius: scaledCornerRadius,
                                                borderColor: cardBorderColor,
                                                contentScale: contentScale
                                            )
                                            .overlay {
                                                if shouldShowDrawingOnboarding, onboardingTargetID == screenshot.id {
                                                    ReportDrawingOnboardingOverlay {
                                                        hasCompletedDrawingOnboarding = true
                                                    }
                                                    .allowsHitTesting(false)
                                                }
                                            }
                                            .onTapGesture {
                                                reportTapLogger.debug("card tap editing=\(self.isComposerEditing, privacy: .public)")
                                                if isComposerEditing {
                                                    dismissKeyboardIfNeeded()
                                                    return
                                                }
                                                openMarkupEditor(for: screenshot)
                                            }

                                            Button {
                                                reportTapLogger.debug("remove tap id=\(screenshot.id.uuidString, privacy: .public)")
                                                removeScreenshot(id: screenshot.id)
                                            } label: {
                                                ZStack {
                                                    Circle()
                                                        .fill(
                                                            colorScheme == .dark
                                                            ? Color(red: 48 / 255, green: 48 / 255, blue: 48 / 255)
                                                            : Color(red: 184 / 255, green: 184 / 255, blue: 184 / 255)
                                                        )
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                                .frame(width: 30, height: 30)
                                                .padding(8)
                                            }
                                            .buttonStyle(.plain)
                                            .zIndex(2)
                                            .contentShape(Rectangle())
                                        }
                                        .id(screenshot.id)
                                    }
                                }
                                .padding(.horizontal, carouselHorizontalInset)
                                .scrollTargetLayout()
                                .animation(.easeInOut(duration: 0.2), value: orderedScreenshots.map(\.id))
                            }
                            .scrollDisabled(orderedScreenshots.count <= 1)
                            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                            .scrollPosition(id: $activeScreenshotID)
                            .onChange(of: activeScreenshotID) { oldValue, newValue in
                                guard oldValue != newValue, newValue != nil else { return }
                                guard !isBatchAddingScreenshots else { return }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.75)
                            }
                        }
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            reportTapLogger.debug("content group tap editing=\(self.isComposerEditing, privacy: .public)")
                            dismissKeyboardIfNeeded()
                        }
                    )
                    .padding(.top, topSpacing)

                    Button {
                        reportTapLogger.debug("hint tap screenshots=\(self.screenshots.count, privacy: .public)")
                        guard let activeID = activeScreenshotID ?? screenshots.last?.id,
                              let screenshot = screenshots.first(where: { $0.id == activeID }) else { return }
                        openMarkupEditor(for: screenshot)
                    } label: {
                        ReportShimmerText(text: "Тапни на скриншот для рисования")
                            .frame(height: noteHeightAnimated)
                            .padding(.top, noteTopAnimated)
                            .opacity(isShowingSubmitSuccess ? 0 : noteOpacity)
                    }
                    .buttonStyle(.plain)
                    .disabled(screenshots.isEmpty)
                    Color.clear
                        .frame(height: noteBottomAnimated)
                        .opacity(isShowingSubmitSuccess ? 0 : noteOpacity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .opacity(isShowingSubmitSuccess ? 0 : 1)
                .scaleEffect(isShowingSubmitSuccess ? 0.99 : 1)
                .animation(.easeInOut(duration: 0.30), value: isShowingSubmitSuccess)
                
                KeyboardAttachedInputBar(
                    text: $reportText,
                    isEditing: $isComposerEditing,
                    onSelectPhoto: {
                        isAttachmentPhotoPickerPresented = true
                    },
                    onSelectFile: {
                        isAttachmentFilePickerPresented = true
                    },
                    onSubmit: {
                        submitReport()
                    },
                    onTextFieldFrameChange: { frame in
                        if composerFrameInScreen != frame {
                            composerFrameInScreen = frame
                        }
                    }
                )
                .ignoresSafeArea()
                .offset(y: isShowingSubmitSuccess ? 80 : 0)
                .opacity(isShowingSubmitSuccess ? 0 : 1)
                .allowsHitTesting(!isShowingSubmitSuccess)
                .animation(.easeInOut(duration: 0.26), value: isShowingSubmitSuccess)

                Text("Спасибо")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.primary)
                    .opacity(isThankYouVisible ? 1 : 0)
                    .scaleEffect(isThankYouVisible ? 1 : 1.02)
                    .offset(y: isThankYouVisible ? 0 : 8)
                    .animation(.easeInOut(duration: 0.30), value: isThankYouVisible)
                    .allowsHitTesting(false)
            }
        }
        .task(id: screenshotPickerItems) {
            guard !screenshotPickerItems.isEmpty else { return }
            await appendScreenshots(from: screenshotPickerItems)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
            let curveRaw = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
            let isKeyboardVisible = endFrame.minY < UIScreen.main.bounds.height
            keyboardTopInScreen = endFrame.minY
            withAnimation(frameAnimation(duration: duration, curveRaw: curveRaw)) {
                frameTransitionProgress = isKeyboardVisible ? 1 : 0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
            keyboardTopInScreen = UIScreen.main.bounds.height
            let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
            let curveRaw = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
            withAnimation(frameAnimation(duration: duration, curveRaw: curveRaw)) {
                frameTransitionProgress = 0
            }
        }
        .onAppear {
            frameTransitionProgress = isComposerEditing ? 1 : 0
            activeScreenshotID = screenshots.last?.id
        }
        .onChange(of: screenshots.count) { oldCount, newCount in
            guard newCount > oldCount else { return }
            activeScreenshotID = screenshots.last?.id
        }
        .photosPicker(
            isPresented: $isAttachmentPhotoPickerPresented,
            selection: $screenshotPickerItems,
            maxSelectionCount: 0,
            matching: .images
        )
        .sheet(isPresented: $isAttachmentFilePickerPresented) {
            ReportFilePicker { pickedURLs in
                isBatchAddingScreenshots = true
                var appendedCount = 0
                for pickedURL in pickedURLs {
                    let hasAccess = pickedURL.startAccessingSecurityScopedResource()
                    defer {
                        if hasAccess {
                            pickedURL.stopAccessingSecurityScopedResource()
                        }
                    }

                    if let data = try? Data(contentsOf: pickedURL),
                       let image = UIImage(data: data) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            screenshots.append(ReportScreenshot(image: image))
                        }
                        appendedCount += 1
                    }
                }
                if appendedCount > 0 {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.8)
                }
                DispatchQueue.main.async {
                    isBatchAddingScreenshots = false
                }
            }
        }
        .sheet(isPresented: $isMarkupEditorPresented, onDismiss: {
            selectedMarkupTarget = nil
            reportTapLogger.debug("markup sheet dismissed")
        }) {
            if let target = selectedMarkupTarget {
                ReportMarkupEditorView(
                    image: target.image,
                    onCancel: {
                        isMarkupEditorPresented = false
                    },
                    onDone: { editedImage in
                        replaceScreenshotImage(id: target.screenshotID, with: editedImage)
                        isMarkupEditorPresented = false
                    }
                )
            }
        }
        .onChange(of: isMarkupEditorPresented) { _, newValue in
            reportTapLogger.debug("markup sheet presented=\(newValue, privacy: .public)")
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationTitle(isShowingSubmitSuccess ? "" : "На что жалуемся?")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func frameAnimation(duration: Double, curveRaw: Int) -> Animation {
        let clampedDuration = max(0.16, duration * 1.12)
        let curve = UIView.AnimationCurve(rawValue: curveRaw) ?? .easeInOut

        switch curve {
        case .easeIn:
            return .easeIn(duration: clampedDuration)
        case .easeOut:
            return .easeOut(duration: clampedDuration)
        case .linear:
            return .linear(duration: clampedDuration)
        case .easeInOut:
            return .easeInOut(duration: clampedDuration)
        @unknown default:
            return .easeInOut(duration: clampedDuration)
        }
    }

    private func lerp(_ from: CGFloat, _ to: CGFloat, t: CGFloat) -> CGFloat {
        from + (to - from) * min(1, max(0, t))
    }

    private func smoothStep(_ t: CGFloat) -> CGFloat {
        let x = min(1, max(0, t))
        return x * x * (3 - 2 * x)
    }

    @ViewBuilder
    private func reportScreenshotCard(
        image: UIImage?,
        cardSize: CGSize,
        cornerRadius: CGFloat,
        borderColor: Color,
        contentScale: CGFloat
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    colorScheme == .dark
                    ? Color(red: 23 / 255, green: 23 / 255, blue: 23 / 255)
                    : Color(red: 242 / 255, green: 240 / 255, blue: 240 / 255)
                )

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardSize.width, height: cardSize.height)
                    .clipped()
            } else {
                VStack(spacing: 0) {
                    Text("+")
                        .font(.system(size: 40 * contentScale, weight: .light))
                        .foregroundColor(Color(red: 66 / 255, green: 139 / 255, blue: 249 / 255))

                    Text("Добавить")
                        .font(.system(size: max(13, 16 * contentScale), weight: .regular))
                        .foregroundColor(Color(red: 66 / 255, green: 139 / 255, blue: 249 / 255))
                        .lineLimit(1)
                        .minimumScaleFactor(13.0 / 16.0)
                        .allowsTightening(true)
                        .padding(.horizontal, 12)
                }
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: 2)
        }
    }

    @MainActor
    private func appendScreenshots(from items: [PhotosPickerItem]) async {
        isBatchAddingScreenshots = true
        var appendedCount = 0
        for item in items {
            let identifier = item.itemIdentifier
            if let identifier, processedPhotoItemIdentifiers.contains(identifier) {
                continue
            }

            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { continue }

            withAnimation(.easeInOut(duration: 0.2)) {
                screenshots.append(ReportScreenshot(image: image))
            }
            appendedCount += 1
            if let identifier {
                processedPhotoItemIdentifiers.insert(identifier)
            }
        }
        if appendedCount > 0 {
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.8)
        }
        DispatchQueue.main.async {
            isBatchAddingScreenshots = false
        }
        screenshotPickerItems = []
    }

    private func removeScreenshot(id: UUID) {
        let orderedBefore = orderedScreenshots
        let currentActiveID = activeScreenshotID ?? orderedBefore.first?.id
        let removedIndex = orderedBefore.firstIndex { $0.id == id }
        let remainingOrdered = orderedBefore.filter { $0.id != id }
        let nextActiveID: UUID?
        if remainingOrdered.isEmpty {
            nextActiveID = nil
        } else if let currentActiveID,
                  currentActiveID != id,
                  remainingOrdered.contains(where: { $0.id == currentActiveID }) {
            nextActiveID = currentActiveID
        } else if let removedIndex {
            let safeIndex = min(removedIndex, remainingOrdered.count - 1)
            nextActiveID = remainingOrdered[safeIndex].id
        } else {
            nextActiveID = remainingOrdered.last?.id
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            screenshots.removeAll { $0.id == id }
            activeScreenshotID = nextActiveID ?? screenshots.last?.id
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.9)
    }

    private func replaceScreenshotImage(id: UUID, with image: UIImage) {
        guard let index = screenshots.firstIndex(where: { $0.id == id }) else { return }
        screenshots[index].image = image
    }

    private func openMarkupEditor(for screenshot: ReportScreenshot) {
        hasOpenedMarkupEditor = true
        selectedMarkupTarget = ReportMarkupEditingTarget(
            screenshotID: screenshot.id,
            image: screenshot.image
        )
        isMarkupEditorPresented = true
    }

    private func dismissKeyboardIfNeeded() {
        guard isComposerEditing else { return }
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func submitReport() {
        let trimmedText = reportText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isShowingSubmitSuccess else { return }

        isThankYouVisible = false
        dismissKeyboardIfNeeded()
        keyboardTopInScreen = UIScreen.main.bounds.height
        withAnimation(.easeOut(duration: 0.22)) {
            frameTransitionProgress = 0
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.easeInOut(duration: 0.26)) {
            isShowingSubmitSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.easeInOut(duration: 0.30)) {
                isThankYouVisible = true
            }
        }
    }
}

private struct ReportShimmerText: View {
    let text: String

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shineProgress: CGFloat = -0.25

    var body: some View {
        let baseColor = Color(red: 146 / 255, green: 153 / 255, blue: 162 / 255)
        let shimmerColor = colorScheme == .dark
            ? Color.white.opacity(0.55)
            : Color(red: 51 / 255, green: 51 / 255, blue: 51 / 255).opacity(0.52)

        Text(text)
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(baseColor)
            .overlay {
                if !reduceMotion {
                    GeometryReader { geo in
                        let width = max(1, geo.size.width)
                        let shineWidth: CGFloat = 24
                        Rectangle()
                            .fill(shimmerColor)
                            .frame(width: shineWidth, height: max(24, geo.size.height * 1.8))
                            .blur(radius: 6)
                            .rotationEffect(.degrees(-11))
                            .offset(x: shineProgress * (width + shineWidth * 2) - shineWidth)
                    }
                    .mask(
                        Text(text)
                            .font(.system(size: 17, weight: .regular))
                    )
                    .allowsHitTesting(false)
                    .onAppear {
                        shineProgress = -0.15
                        withAnimation(.linear(duration: 1.375).delay(3.0).repeatCount(3, autoreverses: false)) {
                            shineProgress = 1.15
                        }
                    }
                }
            }
    }
}

private struct ReportDrawingOnboardingOverlay: View {
    let onCompleted: () -> Void

    @State private var progress: CGFloat = 0
    @State private var strokeOpacity: CGFloat = 0.92
    @State private var hasStarted = false

    var body: some View {
        ReportOnboardingHandCircleStroke()
            .trim(from: 0, to: progress)
            .stroke(
                Color(red: 254 / 255, green: 58 / 255, blue: 58 / 255).opacity(strokeOpacity),
                style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
            )
        .task {
            guard !hasStarted else { return }
            hasStarted = true
            await playDemo()
        }
    }

    @MainActor
    private func playDemo() async {
        for _ in 0..<1 {
            if Task.isCancelled { return }
            progress = 0
            strokeOpacity = 0.92
            withAnimation(.easeInOut(duration: 2.05)) {
                progress = 1
            }
            try? await Task.sleep(nanoseconds: 2_145_000_000)
            if Task.isCancelled { return }
            withAnimation(.easeOut(duration: 0.75)) {
                strokeOpacity = 0
            }
            try? await Task.sleep(nanoseconds: 780_000_000)
        }
        onCompleted()
    }
}

private struct ReportOnboardingHandCircleStroke: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height) * 0.58
        let cx = rect.midX
        let cy = rect.midY

        var path = Path()
        path.move(to: CGPoint(x: cx - side * 0.03, y: cy - side * 0.49))
        path.addCurve(
            to: CGPoint(x: cx - side * 0.46, y: cy - side * 0.04),
            control1: CGPoint(x: cx - side * 0.24, y: cy - side * 0.50),
            control2: CGPoint(x: cx - side * 0.44, y: cy - side * 0.30)
        )
        path.addCurve(
            to: CGPoint(x: cx - side * 0.22, y: cy + side * 0.38),
            control1: CGPoint(x: cx - side * 0.50, y: cy + side * 0.18),
            control2: CGPoint(x: cx - side * 0.36, y: cy + side * 0.35)
        )
        path.addCurve(
            to: CGPoint(x: cx + side * 0.24, y: cy + side * 0.40),
            control1: CGPoint(x: cx - side * 0.08, y: cy + side * 0.43),
            control2: CGPoint(x: cx + side * 0.10, y: cy + side * 0.42)
        )
        path.addCurve(
            to: CGPoint(x: cx + side * 0.46, y: cy + side * 0.05),
            control1: CGPoint(x: cx + side * 0.38, y: cy + side * 0.38),
            control2: CGPoint(x: cx + side * 0.50, y: cy + side * 0.22)
        )
        path.addCurve(
            to: CGPoint(x: cx + side * 0.28, y: cy - side * 0.32),
            control1: CGPoint(x: cx + side * 0.44, y: cy - side * 0.16),
            control2: CGPoint(x: cx + side * 0.36, y: cy - side * 0.28)
        )
        path.addCurve(
            to: CGPoint(x: cx - side * 0.03, y: cy - side * 0.34),
            control1: CGPoint(x: cx + side * 0.18, y: cy - side * 0.39),
            control2: CGPoint(x: cx + side * 0.04, y: cy - side * 0.36)
        )
        return path
    }
}

private struct KeyboardAttachedInputBar: UIViewRepresentable {
    @Binding var text: String
    @Binding var isEditing: Bool
    var onSelectPhoto: () -> Void
    var onSelectFile: () -> Void
    var onSubmit: () -> Void
    var onTextFieldFrameChange: ((CGRect) -> Void)?

    func makeUIView(context: Context) -> KeyboardAttachedInputBarView {
        let view = KeyboardAttachedInputBarView()
        view.textField.delegate = context.coordinator
        view.onTextFieldFrameChange = onTextFieldFrameChange
        view.onSelectPhoto = onSelectPhoto
        view.onSelectFile = onSelectFile
        view.onSubmit = onSubmit
        view.textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        context.coordinator.view = view
        return view
    }

    func updateUIView(_ uiView: KeyboardAttachedInputBarView, context: Context) {
        uiView.onTextFieldFrameChange = onTextFieldFrameChange
        uiView.onSelectPhoto = onSelectPhoto
        uiView.onSelectFile = onSelectFile
        uiView.onSubmit = onSubmit
        uiView.updateAttachmentMenu()
        if uiView.textField.text != text {
            uiView.textField.text = text
        }
        uiView.setFocusedLayout(isEditing, animated: true)
        uiView.updateMicVisibility()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isEditing: $isEditing, onSubmit: onSubmit)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var isEditing: Bool
        let onSubmit: () -> Void
        weak var view: KeyboardAttachedInputBarView?

        init(text: Binding<String>, isEditing: Binding<Bool>, onSubmit: @escaping () -> Void) {
            _text = text
            _isEditing = isEditing
            self.onSubmit = onSubmit
        }

        @objc func textDidChange(_ sender: UITextField) {
            text = sender.text ?? ""
            view?.updateMicVisibility()
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isEditing = true
            view?.setFocusedLayout(true, animated: true)
            view?.updateMicVisibility()
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isEditing = false
            view?.setFocusedLayout(false, animated: true)
            view?.updateMicVisibility()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onSubmit()
            return false
        }
    }
}

private final class KeyboardAttachedInputBarView: PassThroughView {
    let textField = UISearchTextField()
    private let attachmentButton = UIButton(type: .system)
    private let micButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)
    var onTextFieldFrameChange: ((CGRect) -> Void)?
    var onSelectPhoto: (() -> Void)?
    var onSelectFile: (() -> Void)?
    var onSubmit: (() -> Void)?
    private var lastReportedTextFieldFrame: CGRect = .zero
    private var attachmentWidthConstraint: NSLayoutConstraint?
    private var textLeadingWithAttachmentConstraint: NSLayoutConstraint?
    private var textLeadingWithoutAttachmentConstraint: NSLayoutConstraint?
    private var isFocusedLayout: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textField.bringSubviewToFront(micButton)
        textField.bringSubviewToFront(sendButton)

        let frameInScreen = textField.convert(textField.bounds, to: nil)
        guard shouldReportFrame(frameInScreen) else { return }

        lastReportedTextFieldFrame = frameInScreen
        onTextFieldFrameChange?(frameInScreen)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAttachmentAppearance()
    }

    private func setup() {
        backgroundColor = .clear

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Опиши, что болит"
        textField.textAlignment = .left
        textField.leftView = nil
        textField.leftViewMode = .never
        textField.returnKeyType = .default
        textField.autocorrectionType = .yes
        textField.autocapitalizationType = .sentences
        textField.clearButtonMode = .never

        micButton.translatesAutoresizingMaskIntoConstraints = false
        micButton.tintColor = .secondaryLabel
        micButton.setImage(UIImage(systemName: "mic"), for: .normal)
        micButton.addAction(UIAction { [weak self] _ in
            self?.textField.becomeFirstResponder()
        }, for: .touchUpInside)

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(systemName: "arrow.up"), for: .normal)
        sendButton.tintColor = .white
        sendButton.backgroundColor = UIColor(red: 10 / 255, green: 132 / 255, blue: 1, alpha: 1)
        sendButton.layer.cornerRadius = 16
        sendButton.layer.cornerCurve = .continuous
        sendButton.alpha = 0
        sendButton.transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
        sendButton.isUserInteractionEnabled = false
        sendButton.addAction(UIAction { [weak self] _ in
            self?.onSubmit?()
        }, for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTouchDown), for: .touchDown)
        sendButton.addTarget(self, action: #selector(sendButtonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        let textRightSpacer = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 44))
        textRightSpacer.isUserInteractionEnabled = false
        textField.rightView = textRightSpacer
        textField.rightViewMode = .always

        attachmentButton.translatesAutoresizingMaskIntoConstraints = false
        attachmentButton.contentHorizontalAlignment = .center
        attachmentButton.contentVerticalAlignment = .center
        attachmentButton.showsMenuAsPrimaryAction = true
        attachmentButton.layer.cornerRadius = 22
        attachmentButton.layer.cornerCurve = .continuous
        attachmentButton.clipsToBounds = false
        attachmentButton.layer.masksToBounds = false
        attachmentButton.layer.borderWidth = 1

        updateAttachmentAppearance()
        updateAttachmentMenu()

        addSubview(textField)
        textField.addSubview(micButton)
        textField.addSubview(sendButton)
        addSubview(attachmentButton)

        let bottomConstraint: NSLayoutConstraint
        if #available(iOS 15.0, *) {
            bottomConstraint = textField.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor, constant: -8)
        } else {
            bottomConstraint = textField.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -14)
        }

        let attachmentLeading = attachmentButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        let attachmentWidth = attachmentButton.widthAnchor.constraint(equalToConstant: 44)
        let textLeadingWithAttachment = textField.leadingAnchor.constraint(equalTo: attachmentButton.trailingAnchor, constant: 10)
        let textLeadingWithoutAttachment = textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        textLeadingWithoutAttachment.isActive = false
        attachmentWidth.priority = UILayoutPriority(999)
        textLeadingWithAttachment.priority = UILayoutPriority(999)

        attachmentWidthConstraint = attachmentWidth
        textLeadingWithAttachmentConstraint = textLeadingWithAttachment
        textLeadingWithoutAttachmentConstraint = textLeadingWithoutAttachment

        NSLayoutConstraint.activate([
            attachmentLeading,
            attachmentWidth,
            attachmentButton.heightAnchor.constraint(equalToConstant: 44),
            attachmentButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            textLeadingWithAttachment,
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 44),
            bottomConstraint,
            micButton.trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: -10),
            micButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 24),
            micButton.heightAnchor.constraint(equalToConstant: 24),
            sendButton.trailingAnchor.constraint(equalTo: textField.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 32),
            sendButton.heightAnchor.constraint(equalToConstant: 32),
        ])

        isFocusedLayout = true
        setFocusedLayout(false, animated: false)
        updateMicVisibility()
    }

    func updateAttachmentMenu() {
        let photoAction = UIAction(
            title: "Добавить фото",
            image: UIImage(systemName: "photo.on.rectangle")
        ) { [weak self] _ in
            self?.onSelectPhoto?()
        }

        let fileAction = UIAction(
            title: "Добавить файл",
            image: UIImage(systemName: "doc")
        ) { [weak self] _ in
            self?.onSelectFile?()
        }

        attachmentButton.menu = UIMenu(children: [photoAction, fileAction])
    }

    private func shouldReportFrame(_ frame: CGRect) -> Bool {
        abs(frame.minX - lastReportedTextFieldFrame.minX) > 0.5 ||
        abs(frame.minY - lastReportedTextFieldFrame.minY) > 0.5 ||
        abs(frame.width - lastReportedTextFieldFrame.width) > 0.5 ||
        abs(frame.height - lastReportedTextFieldFrame.height) > 0.5
    }

    private func updateAttachmentAppearance() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        attachmentButton.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        attachmentButton.setImage(UIImage(systemName: "paperclip"), for: .normal)
        attachmentButton.tintColor = isDark
            ? .white
            : UIColor(red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1)
        micButton.tintColor = isDark
            ? .white
            : UIColor(red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1)
        attachmentButton.backgroundColor = isDark
            ? (textField.backgroundColor ?? UIColor.secondarySystemBackground)
            : UIColor.white.withAlphaComponent(0.70)
        attachmentButton.layer.borderColor = isDark
            ? UIColor.separator.withAlphaComponent(0.45).cgColor
            : UIColor.white.cgColor
        if isDark {
            attachmentButton.layer.shadowColor = UIColor.clear.cgColor
            attachmentButton.layer.shadowOpacity = 0
            attachmentButton.layer.shadowRadius = 0
            attachmentButton.layer.shadowOffset = .zero
        } else {
            attachmentButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
            attachmentButton.layer.shadowOpacity = 1
            attachmentButton.layer.shadowRadius = 12.2
            attachmentButton.layer.shadowOffset = .zero
        }
    }

    func updateMicVisibility() {
        let hasTypedText = !(textField.text ?? "").isEmpty
        UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]) {
            self.micButton.alpha = hasTypedText ? 0 : 1
            self.micButton.transform = hasTypedText
                ? CGAffineTransform(scaleX: 0.9, y: 0.9)
                : .identity
            self.sendButton.alpha = hasTypedText ? 1 : 0
            self.sendButton.transform = hasTypedText
                ? CGAffineTransform(scaleX: 1, y: 1)
                : CGAffineTransform(scaleX: 0.92, y: 0.92)
        }
        micButton.isUserInteractionEnabled = !hasTypedText
        sendButton.isUserInteractionEnabled = hasTypedText
    }

    func setFocusedLayout(_ focused: Bool, animated: Bool) {
        guard focused != isFocusedLayout else { return }
        isFocusedLayout = focused

        attachmentWidthConstraint?.constant = focused ? 0 : 44
        textLeadingWithAttachmentConstraint?.isActive = !focused
        textLeadingWithoutAttachmentConstraint?.isActive = focused

        let updates = {
            self.attachmentButton.alpha = focused ? 0 : 1
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction],
                animations: updates
            )
        } else {
            updates()
        }

        attachmentButton.isUserInteractionEnabled = !focused
    }

    @objc
    private func sendButtonTouchDown() {
        UIView.animate(
            withDuration: 0.12,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction]
        ) {
            self.sendButton.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }
    }

    @objc
    private func sendButtonTouchUp() {
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            usingSpringWithDamping: 0.72,
            initialSpringVelocity: 0.15,
            options: [.beginFromCurrentState, .allowUserInteraction]
        ) {
            self.sendButton.transform = .identity
        }
    }
}

private struct ReportFilePicker: UIViewControllerRepresentable {
    let onPick: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.image, .data], asCopy: true)
        controller.allowsMultipleSelection = true
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void

        init(onPick: @escaping ([URL]) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard !urls.isEmpty else { return }
            onPick(urls)
        }
    }
}

private struct ReportScreenshot: Identifiable {
    let id = UUID()
    var image: UIImage
}

private struct ReportMarkupEditingTarget: Identifiable {
    let screenshotID: UUID
    let image: UIImage
    var id: UUID { screenshotID }
}

private struct ReportMarkupEditorView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onDone: (UIImage) -> Void

    @State private var drawing = PKDrawing()
    @State private var canvasSize: CGSize = .zero
    @State private var canvasView: PKCanvasView?
    @State private var canUndo: Bool = false
    @State private var canRedo: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let contentContainer = CGSize(
                    width: max(1, proxy.size.width - 32),
                    height: max(1, proxy.size.height - 32)
                )
                let fittedSize = aspectFitSize(for: image.size, in: contentContainer)
                let cornerRadius: CGFloat = 24
                let borderColor: Color = colorScheme == .dark
                    ? Color.white.opacity(0.10)
                    : Color(red: 0 / 255, green: 16 / 255, blue: 36 / 255).opacity(0.12)

                ZStack {
                    Color(
                        colorScheme == .dark
                        ? Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
                        : Color(.systemGroupedBackground)
                    )
                        .ignoresSafeArea()

                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                colorScheme == .dark
                                ? Color(red: 23 / 255, green: 23 / 255, blue: 23 / 255)
                                : Color(red: 242 / 255, green: 240 / 255, blue: 240 / 255)
                            )

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: fittedSize.width, height: fittedSize.height)
                            .clipped()

                        ReportMarkupCanvasView(
                            drawing: $drawing,
                            onCanvasReady: { canvas in
                                canvasView = canvas
                                refreshUndoRedoState()
                            },
                            onUndoRedoStateChange: { undo, redo in
                                canUndo = undo
                                canRedo = redo
                            }
                        )
                            .frame(width: fittedSize.width, height: fittedSize.height)
                            .onAppear {
                                canvasSize = fittedSize
                            }
                            .onChange(of: fittedSize) { _, newValue in
                                canvasSize = newValue
                            }
                    }
                    .frame(width: fittedSize.width, height: fittedSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(borderColor, lineWidth: 2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel) {
                        dismiss()
                        onCancel()
                    } label: {
                        Text("Отмена")
                    }
                    .contentShape(Rectangle())
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        canvasView?.undoManager?.undo()
                        refreshUndoRedoState()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(!canUndo)

                    Button {
                        canvasView?.undoManager?.redo()
                        refreshUndoRedoState()
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    .disabled(!canRedo)

                    Button {
                        let result = mergedImage()
                        dismiss()
                        onDone(result)
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func mergedImage() -> UIImage {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return image }

        let sx = image.size.width / canvasSize.width
        let sy = image.size.height / canvasSize.height
        let transformedDrawing = drawing.transformed(using: CGAffineTransform(scaleX: sx, y: sy))
        let drawingImage = transformedDrawing.image(from: CGRect(origin: .zero, size: image.size), scale: 1)

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            drawingImage.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private func aspectFitSize(for imageSize: CGSize, in container: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0, container.width > 0, container.height > 0 else {
            return .zero
        }

        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = container.width / container.height

        if imageAspect > containerAspect {
            let width = container.width
            return CGSize(width: width, height: width / imageAspect)
        } else {
            let height = container.height
            return CGSize(width: height * imageAspect, height: height)
        }
    }

    private func refreshUndoRedoState() {
        canUndo = canvasView?.undoManager?.canUndo ?? false
        canRedo = canvasView?.undoManager?.canRedo ?? false
    }
}

private struct ReportMarkupCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var onCanvasReady: (PKCanvasView) -> Void = { _ in }
    var onUndoRedoStateChange: (Bool, Bool) -> Void = { _, _ in }

    func makeUIView(context: Context) -> PKCanvasView {
        let view = ReportCanvasView()
        view.delegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = .clear
        view.drawing = drawing
        view.drawingPolicy = .anyInput
        view.alwaysBounceVertical = false
        view.alwaysBounceHorizontal = false
        view.contentInset = .zero
        view.minimumZoomScale = 1
        view.maximumZoomScale = 1
        view.tool = PKInkingTool(.marker, color: .systemRed, width: 8)
        let coordinator = context.coordinator
        view.onWindowAttached = { [weak coordinator] canvas in
            coordinator?.activateToolPickerIfNeeded(for: canvas)
        }
        DispatchQueue.main.async {
            context.coordinator.activateToolPickerIfNeeded(for: view)
        }
        onCanvasReady(view)
        onUndoRedoStateChange(view.undoManager?.canUndo ?? false, view.undoManager?.canRedo ?? false)
        return view
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        context.coordinator.activateToolPickerIfNeeded(for: uiView)
        onUndoRedoStateChange(uiView.undoManager?.canUndo ?? false, uiView.undoManager?.canRedo ?? false)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing, onUndoRedoStateChange: onUndoRedoStateChange)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        let onUndoRedoStateChange: (Bool, Bool) -> Void
        private let toolPicker = PKToolPicker()
        private let defaultTool = PKInkingTool(
            .marker,
            color: UIColor(red: 254 / 255, green: 58 / 255, blue: 58 / 255, alpha: 1),
            width: 8
        )
        private weak var currentCanvasView: PKCanvasView?

        init(drawing: Binding<PKDrawing>, onUndoRedoStateChange: @escaping (Bool, Bool) -> Void) {
            _drawing = drawing
            self.onUndoRedoStateChange = onUndoRedoStateChange
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
            onUndoRedoStateChange(canvasView.undoManager?.canUndo ?? false, canvasView.undoManager?.canRedo ?? false)
        }

        func activateToolPickerIfNeeded(for canvasView: PKCanvasView) {
            guard let window = canvasView.window else {
                return
            }
            canvasView.tool = defaultTool
            attach(toolPicker: toolPicker, to: canvasView)
        }

        private func attach(toolPicker picker: PKToolPicker, to canvasView: PKCanvasView) {
            if currentCanvasView !== canvasView, let currentCanvasView {
                picker.removeObserver(currentCanvasView)
            }
            picker.setVisible(true, forFirstResponder: canvasView)
            picker.addObserver(canvasView)
            picker.selectedTool = defaultTool
            _ = canvasView.becomeFirstResponder()
            currentCanvasView = canvasView

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak picker, weak canvasView] in
                guard let picker, let canvasView else { return }
                picker.setVisible(true, forFirstResponder: canvasView)
                picker.selectedTool = self.defaultTool
                canvasView.tool = self.defaultTool
                _ = canvasView.becomeFirstResponder()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak picker, weak canvasView] in
                guard let picker, let canvasView else { return }
                picker.setVisible(true, forFirstResponder: canvasView)
                picker.selectedTool = self.defaultTool
                canvasView.tool = self.defaultTool
                _ = canvasView.becomeFirstResponder()
            }
        }
    }
}

private final class ReportCanvasView: PKCanvasView {
    var onWindowAttached: ((PKCanvasView) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        onWindowAttached?(self)
    }
}

private class PassThroughView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews where !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled {
            let convertedPoint = convert(point, to: subview)
            if subview.point(inside: convertedPoint, with: event) {
                return true
            }
        }
        return false
    }
}

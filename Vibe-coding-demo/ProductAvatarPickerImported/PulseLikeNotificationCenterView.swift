//
//  NotificationCenterView.swift
//  ProductAvatarPicker
//
//  Центр уведомлений с трансформацией Острова
//

import SwiftUI

struct PulseLikeNotificationCenterView: View {
    @StateObject private var viewModel = PulseLikeNotificationCenterViewModel()
    @State private var staticCloseButtonOpacity: CGFloat = 0
    @State private var staticCloseButtonOffsetY: CGFloat = -18
    @State private var tapExpandProgress: CGFloat = 0
    @State private var tapCollapsedLabelOpacity: CGFloat = 1
    @State private var tapCollapsedLabelOffsetY: CGFloat = 0
    @State private var isTapClosing: Bool = false
    @State private var tapCloseProgress: CGFloat = 0
    @State private var isOpeningByIslandTap: Bool = false
    @State private var isClosingByCloseButtonTap: Bool = false
    @State private var didLogMainDragInCurrentGesture: Bool = false
    @State private var isMainDragTracking: Bool = false
    @State private var mainPullDistance: CGFloat = 0
    @State private var isMainRefreshing: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Черная полоска (gap) тоже активирует свайп открытия ЦУ
    private let swipeGapHeight: CGFloat = 8
    // Настраиваемые параметры overlay-анимаций (независимо по лейблу/кнопке)
    private let tapTransitionDuration: Double = 0.8
    private let tapTransitionCurve = Animation.timingCurve(0.34, 1.15, 0.25, 1.0, duration: 0.8)
    private let closeButtonHideDuration: Double = 0.14
    private let closeButtonOpenStartOffset: CGFloat = -18
    private let collapsedLabelTapCloseStart: CGFloat = 0.8
    private let collapsedLabelTapCloseEnd: CGFloat = 1.0
    // Базовая геометрия статичной "Главной" для сценария "штора поверх"
    private let collapsedIslandBaseHeight: CGFloat = 108
    private let baseGap: CGFloat = 8
    private let mainDeadZoneHeight: CGFloat = 16
    private let mainRefreshThreshold: CGFloat = 56
    private let mainPullResistance: CGFloat = 0.6
    private let mainPullMaxDistance: CGFloat = 64
    
    private let importantNotifications: [NotificationCardModel] = [
        .init(
            title: "Новый штраф 500 ₽",
            subtitle: "Geely Tugella",
            icon: "₽",
            iconSystemName: nil
        ),
        .init(
            title: "Начислили кэшбек",
            subtitle: "+500 ₽ на Black",
            icon: "₽",
            iconSystemName: nil
        ),
        .init(
            title: "Начислили кэшбек",
            subtitle: "+500 ₽ на Black",
            icon: "₽",
            iconSystemName: nil
        )
    ]
    
    private let interestingNotifications: [NotificationCardModel] = [
        .init(
            title: "Возвращайтесь в 5 букв",
            subtitle: "И забирайте бонус",
            icon: nil,
            iconSystemName: "diamond.fill"
        ),
        .init(
            title: "Возвращайтесь в 5 букв",
            subtitle: "И забирайте бонус",
            icon: nil,
            iconSystemName: "diamond.fill"
        ),
        .init(
            title: "Возвращайтесь в 5 букв",
            subtitle: "И забирайте бонус",
            icon: nil,
            iconSystemName: "diamond.fill"
        ),
        .init(
            title: "Возвращайтесь в 5 букв",
            subtitle: "И забирайте бонус",
            icon: nil,
            iconSystemName: "diamond.fill"
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let screenWidth = geometry.size.width
            let mainVisibleHeight = max(0, screenHeight - collapsedIslandBaseHeight - baseGap)
            let spinnerBaseY = geometry.safeAreaInsets.top + 64
            let pullRevealHeight = max(0, mainPullDistance + 40)
            
            ZStack(alignment: .top) {
                // Базовый фон экрана.
                Color.black
                    .ignoresSafeArea()
                
                // Светлая "вскрытая" зона pull-to-refresh над двигающимся экраном.
                refreshRevealBackgroundColor
                    .frame(width: screenWidth, height: pullRevealHeight)
                    .position(x: screenWidth / 2, y: pullRevealHeight / 2)
                    .allowsHitTesting(false)
                    .zIndex(0.2)

                // Весь экранный блок (остров + главная + разделитель) тянется вниз при pull-to-refresh.
                ZStack(alignment: .top) {
                    // Главная в Pulse-like сценарии статична и не участвует в анимации ЦУ
                    contentView(screenHeight: screenHeight)
                        .frame(width: screenWidth, height: mainVisibleHeight)
                        .position(
                            x: screenWidth / 2,
                            y: collapsedIslandBaseHeight + baseGap + (mainVisibleHeight / 2)
                        )
                        .zIndex(0)

                    // Легкое затемнение "Главной" по мере открытия шторы
                    Color.black
                        .opacity(underlayDimmingOpacity(screenHeight: screenHeight))
                        .frame(width: screenWidth, height: mainVisibleHeight)
                        .position(
                            x: screenWidth / 2,
                            y: collapsedIslandBaseHeight + baseGap + (mainVisibleHeight / 2)
                        )
                        .allowsHitTesting(false)
                        .zIndex(1)

                    // Черная полоска под островом — в зоне свайпа (не влияет на layout/фрейм острова)
                    Color.clear
                        .frame(height: swipeGapHeight)
                        .position(
                            x: geometry.size.width / 2,
                            y: viewModel.islandHeight(screenHeight: screenHeight) + (swipeGapHeight / 2)
                        )
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    guard !viewModel.isExpanded else { return }
                                    guard canStartOpeningDrag(value) else { return }
                                    viewModel.handleDrag(
                                        translation: value.translation.height,
                                        screenHeight: screenHeight
                                    )
                                }
                                .onEnded { value in
                                    guard !viewModel.isExpanded else { return }
                                    guard canStartOpeningDrag(value) else { return }
                                    print(
                                        String(
                                            format: "🧭 [NCDebug] drag-end raw=%.1f predicted=%.1f",
                                            value.translation.height,
                                            value.predictedEndTranslation.height
                                        )
                                    )
                                    viewModel.handleDragEnd(
                                        translation: value.translation.height,
                                        velocity: value.predictedEndTranslation.height,
                                        screenHeight: screenHeight
                                    )
                                }
                        )
                        .allowsHitTesting(!viewModel.isExpanded)
                        .zIndex(1)
                    
                    // ЦУ-штора поверх "Главной"
                    islandView(screenHeight: screenHeight)
                        .frame(height: viewModel.islandHeight(screenHeight: screenHeight))
                        .position(
                            x: geometry.size.width / 2,
                            y: viewModel.islandHeight(screenHeight: screenHeight) / 2
                        )
                        .zIndex(2)
                    
                    // Grabber под шторой (вне шторы), только во время drag
                    Capsule()
                        .fill(primaryTextColor.opacity(0.22))
                        .frame(width: 36, height: 5)
                        .opacity(viewModel.isDragging ? 1 : 0)
                        .position(
                            x: geometry.size.width / 2,
                            y: viewModel.islandHeight(screenHeight: screenHeight) + 18
                        )
                        .allowsHitTesting(false)
                        .animation(.easeOut(duration: 0.12), value: viewModel.isDragging)
                        .zIndex(3)

                }
                .offset(y: mainPullDistance)

                // Системный индикатор рефреша в верхней "вскрытой" зоне.
                SystemRefreshSpinner(isAnimating: mainPullDistance > 6 || isMainRefreshing)
                    .opacity(mainPullDistance > 6 || isMainRefreshing ? 1 : 0)
                    .position(
                        x: screenWidth / 2,
                        y: spinnerBaseY + min(max(mainPullDistance * 0.25, 0), 28)
                    )
                    .zIndex(6)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        handleMainPullChanged(value)
                    }
                    .onEnded { value in
                        handleMainPullEnded(value)
                    }
            )
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onAppear {
            // Начальное состояние экрана должно быть стабильным, без "въезда" лейбла.
            if viewModel.isExpanded {
                syncCloseButtonOpacity(for: true)
            } else {
                staticCloseButtonOpacity = 0
                staticCloseButtonOffsetY = 0
                tapExpandProgress = 0
                tapCollapsedLabelOpacity = 1
                tapCollapsedLabelOffsetY = 0
                isTapClosing = false
                tapCloseProgress = 0
            }
        }
        .onChange(of: viewModel.isExpanded) { _, expanded in
            syncCloseButtonOpacity(for: expanded)
        }
    }
    
    // MARK: - Island (Остров)
    
    private func islandView(screenHeight: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            // Белый фон со скруглениями
            RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(islandBackgroundColor)
            
            // Контент ЦУ с плавным появлением/исчезновением
            notificationCenterExpandedContent(screenHeight: screenHeight)
                .zIndex(0)
            
            // Контент - оба текста одновременно с разной прозрачностью
            ZStack(alignment: .bottom) {
                // Текст "Все уведомления" - исчезает быстро
                Text("Все уведомления")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(primaryTextColor)
                    .kerning(-0.24)
                    .padding(.bottom, 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .opacity(collapsedTextOpacity(screenHeight: screenHeight))
                .offset(y: collapsedTextOffsetY(screenHeight: screenHeight))
                
                // Текст "Остров" - появляется в конце
                VStack(spacing: 0) {
                    Spacer()
                    Color.clear.frame(height: 1)
                }
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            
            // Кнопка закрытия - overlay поверх
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        if viewModel.isExpanded {
                            isClosingByCloseButtonTap = true
                            viewModel.toggleExpanded()
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(iconColor)
                            .frame(width: 28, height: 28)
                            .background(iconBackgroundColor)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60) // Под статус бар
                
                Spacer()
            }
            .zIndex(3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(
            color: Color.black.opacity(viewModel.curtainShadowOpacity(screenHeight: screenHeight)),
            radius: 40,
            x: 0,
            y: 10
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    guard !viewModel.isExpanded else { return }
                    guard canStartOpeningDrag(value) else { return }
                    viewModel.handleDrag(
                        translation: value.translation.height,
                        screenHeight: screenHeight
                    )
                }
                .onEnded { value in
                    guard !viewModel.isExpanded else { return }
                    guard canStartOpeningDrag(value) else { return }
                    // Freeze current visual state before switching from live-drag values
                    // to static values on gesture end, so close button does not jump.
                    staticCloseButtonOpacity = viewModel.closeButtonOpacity(screenHeight: screenHeight)
                    staticCloseButtonOffsetY = viewModel.closeButtonOffsetY(screenHeight: screenHeight)
                    viewModel.handleDragEnd(
                        translation: value.translation.height,
                        velocity: value.predictedEndTranslation.height,
                        screenHeight: screenHeight
                    )
                }
        )
        .onTapGesture {
            guard !viewModel.isExpanded else { return }
            isOpeningByIslandTap = true
            viewModel.toggleExpanded()
        }
    }
    
    private func notificationCenterExpandedContent(screenHeight: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                notificationSection(
                    title: "Важное",
                    cards: importantNotifications
                )
                
                notificationSection(
                    title: "Интересное",
                    cards: interestingNotifications
                )
            }
            .padding(.top, 92)
            .padding(.bottom, 32)
        }
        .opacity(expandedContentOpacity(screenHeight: screenHeight))
        .allowsHitTesting(viewModel.isExpanded)
        .zIndex(0)
    }

    private func closeButtonOverlay(screenHeight: CGFloat) -> some View {
        VStack {
            Spacer()

            Button(action: {
                guard viewModel.isExpanded else { return }
                isClosingByCloseButtonTap = true
                viewModel.toggleExpanded()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Закрыть")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(closeButtonBackgroundColor)
                .clipShape(Capsule())
            }
            .buttonStyle(ScalePressButtonStyle())
            .opacity(closeButtonOpacity(screenHeight: screenHeight))
            .offset(y: closeButtonOffsetY(screenHeight: screenHeight))
            .allowsHitTesting(viewModel.isExpanded)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func closeButtonOpacity(screenHeight: CGFloat) -> CGFloat {
        if viewModel.isDragging {
            return viewModel.closeButtonOpacity(screenHeight: screenHeight)
        }
        
        if isTapClosing {
            return max(0, 1 - tapCloseProgress)
        }

        if viewModel.lastExpandTrigger == .tap {
            return closeButtonRevealFromTapProgress()
        }

        return staticCloseButtonOpacity
    }
    
    private func expandedContentOpacity(screenHeight: CGFloat) -> CGFloat {
        if viewModel.isDragging {
            return viewModel.expandedContentOpacity(screenHeight: screenHeight)
        }
        
        if viewModel.lastExpandTrigger == .tap {
            return viewModel.expandedContentOpacity(from: tapExpandProgress)
        }
        
        return viewModel.expandedContentOpacity(screenHeight: screenHeight)
    }
    
    private func collapsedTextOpacity(screenHeight: CGFloat) -> CGFloat {
        // Drag всегда должен работать по базовой логике VM.
        if viewModel.isDragging {
            return viewModel.collapsedTextOpacity(screenHeight: screenHeight)
        }
        
        // Для закрытия по tap: привязываем проявление к той же шкале, что и схлопывание ЦУ
        // (tapExpandProgress: 1 -> 0), а не к короткой анимации скрытия кнопки.
        if isTapClosing {
            let closeProgress = min(max(1 - tapExpandProgress, 0), 1)
            return min(
                max(
                    (closeProgress - collapsedLabelTapCloseStart) /
                    max(collapsedLabelTapCloseEnd - collapsedLabelTapCloseStart, 0.001),
                    0
                ),
                1
            )
        }
        
        // Для открытия по tap повторяем кривую исчезновения как у drag.
        if viewModel.lastExpandTrigger == .tap {
            return viewModel.collapsedTextOpacity(from: tapExpandProgress)
        }
        
        return viewModel.collapsedTextOpacity(screenHeight: screenHeight)
    }
    
    private func collapsedTextOffsetY(screenHeight: CGFloat) -> CGFloat {
        // Позиция лейбла фиксирована у низа острова, как в drag.
        return 0
    }

    private func closeButtonOffsetY(screenHeight: CGFloat) -> CGFloat {
        if isTapClosing {
            return 0
        }
        
        if viewModel.isDragging {
            return viewModel.closeButtonOffsetY(screenHeight: screenHeight)
        }

        if viewModel.lastExpandTrigger == .tap {
            return closeButtonOffsetFromTapProgress(isExpanded: viewModel.isExpanded)
        }

        return staticCloseButtonOffsetY
    }

    private func syncCloseButtonOpacity(for isExpanded: Bool) {
        if isExpanded {
            isTapClosing = false
            tapCloseProgress = 0
            
            if viewModel.lastExpandTrigger == .drag && !isOpeningByIslandTap {
                staticCloseButtonOpacity = 1
                staticCloseButtonOffsetY = 0
                tapCollapsedLabelOpacity = 0
                tapCollapsedLabelOffsetY = 8
            } else {
                staticCloseButtonOpacity = 0
                staticCloseButtonOffsetY = closeButtonOpenStartOffset
                tapExpandProgress = 0
                tapCollapsedLabelOpacity = 1
                tapCollapsedLabelOffsetY = 0
                withAnimation(.easeOut(duration: 0.10)) {
                    tapCollapsedLabelOpacity = 0
                    tapCollapsedLabelOffsetY = 8
                }
                withAnimation(tapTransitionCurve) {
                    tapExpandProgress = 1
                }
            }
            isOpeningByIslandTap = false
            isClosingByCloseButtonTap = false
        } else {
            if isClosingByCloseButtonTap {
                // Закрываем по той же шкале, что и открытие: это синхронизирует
                // исчезновение "Важное"/контента и появление "Все уведомления".
                isTapClosing = true
                tapCloseProgress = 0
                tapExpandProgress = 1
                tapCollapsedLabelOpacity = 1
                tapCollapsedLabelOffsetY = 0
                
                withAnimation(tapTransitionCurve) {
                    tapExpandProgress = 0
                }
                withAnimation(.easeOut(duration: closeButtonHideDuration)) {
                    tapCloseProgress = 1
                }
                isClosingByCloseButtonTap = false
                return
            }
            
            isTapClosing = false
            withAnimation(.easeOut(duration: 0.12)) {
                staticCloseButtonOpacity = 0
                staticCloseButtonOffsetY = 0
                tapExpandProgress = 0
            }
            tapCollapsedLabelOpacity = 1
            tapCollapsedLabelOffsetY = 0
        }
    }

    private func closeButtonRevealFromTapProgress() -> CGFloat {
        viewModel.closeButtonRevealProgress(from: tapExpandProgress)
    }

    private func closeButtonOffsetFromTapProgress() -> CGFloat {
        closeButtonOffsetFromTapProgress(isExpanded: viewModel.isExpanded)
    }
    
    private func closeButtonOffsetFromTapProgress(isExpanded: Bool) -> CGFloat {
        let reveal = closeButtonRevealFromTapProgress()
        // На открытии кнопка заходит сверху вниз.
        // На закрытии оставляем offset = 0, чтобы не было скачка.
        guard isExpanded else { return 0 }
        let startOffset: CGFloat = closeButtonOpenStartOffset
        return (1 - reveal) * startOffset
    }
    
    private func underlayDimmingOpacity(screenHeight: CGFloat) -> CGFloat {
        if viewModel.isDragging {
            return viewModel.underlayDimmingOpacityWithDivider(screenHeight: screenHeight)
        }
        
        if viewModel.lastExpandTrigger == .tap || isTapClosing {
            let dividerProgress = 8 / max(screenHeight - 108, 1)
            guard tapExpandProgress > dividerProgress else { return 0 }
            return viewModel.underlayDimmingOpacity(from: tapExpandProgress)
        }
        
        return viewModel.underlayDimmingOpacityWithDivider(screenHeight: screenHeight)
    }
    
    // Открытие шторы разрешаем только из верхней интерактивной зоны:
    // остров + черная разделительная линия.
    private func canStartOpeningDrag(_ value: DragGesture.Value) -> Bool {
        let allowedStartY = collapsedIslandBaseHeight + swipeGapHeight
        return value.startLocation.y <= allowedStartY
    }
    
    private func notificationSection(title: String, cards: [NotificationCardModel]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 30, weight: .bold))
                .kerning(0.36)
                .foregroundColor(primaryTextColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            VStack(spacing: 20) {
                ForEach(cards) { card in
                    notificationCard(card)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 28)
    }
    
    private func notificationCard(_ model: NotificationCardModel) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(model.title)
                    .font(.system(size: 17, weight: .semibold))
                    .kerning(-0.41)
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                
                Text(model.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .kerning(-0.24)
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 12)
            
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                
                if let icon = model.icon {
                    Text(icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(primaryTextColor)
                } else if let iconSystemName = model.iconSystemName {
                    Image(systemName: iconSystemName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                }
            }
            .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .frame(height: 80)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(
            color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.10),
            radius: 20,
            x: 0,
            y: 5
        )
    }
    
    // MARK: - Content View (Главная)
    
    private func contentView(screenHeight: CGFloat) -> some View {
        let mainHeight = max(0, screenHeight - collapsedIslandBaseHeight - baseGap)
        
        return UnevenRoundedRectangle(
            topLeadingRadius: 32,
            topTrailingRadius: 32
        )
        .fill(contentBackgroundStyle)
        .frame(height: mainHeight)
        .frame(maxWidth: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .onAppear {
            print(
                String(
                    format: "🧭 [PulseRefresh] main content appeared h=%.1f expanded=%@",
                    mainHeight,
                    viewModel.isExpanded.description
                )
            )
        }
        .onChange(of: viewModel.isExpanded) { _, expanded in
            print("🧭 [PulseRefresh] expanded changed -> \(expanded)")
            if expanded {
                mainPullDistance = 0
                didLogMainDragInCurrentGesture = false
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                if viewModel.isExpanded {
                    viewModel.toggleExpanded()
                }
            }
        )
    }

    private func handleMainPullChanged(_ value: DragGesture.Value) {
        guard canStartMainRefreshDrag(value) else { return }
        
        if !isMainDragTracking {
            isMainDragTracking = true
        }
        
        if !didLogMainDragInCurrentGesture && isMainDragTracking {
            didLogMainDragInCurrentGesture = true
            print(
                String(
                    format: "🧭 [PulseRefresh] drag begin startY=%.1f startX=%.1f",
                    value.startLocation.y,
                    value.startLocation.x
                )
            )
        }
        
        guard value.translation.height > 0 else { return }
        
        let pulled = min(value.translation.height * mainPullResistance, mainPullMaxDistance)
        mainPullDistance = pulled
        
        print(
            String(
                format: "🧭 [PulseRefresh] drag changed dy=%.1f pulled=%.1f threshold=%.1f",
                value.translation.height,
                pulled,
                mainRefreshThreshold
            )
        )
    }
    
    private func handleMainPullEnded(_ value: DragGesture.Value) {
        guard isMainDragTracking else { return }
        isMainDragTracking = false
        
        print(
            String(
                format: "🧭 [PulseRefresh] drag end dy=%.1f predicted=%.1f pulled=%.1f expanded=%@",
                value.translation.height,
                value.predictedEndTranslation.height,
                mainPullDistance,
                viewModel.isExpanded.description
            )
        )
        
        if mainPullDistance >= mainRefreshThreshold && !isMainRefreshing {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            Task { await refreshMainContent() }
        } else {
            withAnimation(.easeOut(duration: 0.16)) {
                mainPullDistance = 0
            }
        }
        
        didLogMainDragInCurrentGesture = false
    }
    
    private func canStartMainRefreshDrag(_ value: DragGesture.Value) -> Bool {
        guard !viewModel.isExpanded else { return false }
        guard !isMainRefreshing else { return false }
        
        let mainStartY = collapsedIslandBaseHeight + baseGap + mainDeadZoneHeight
        return value.startLocation.y >= mainStartY
    }
    
    private func refreshMainContent() async {
        guard !viewModel.isExpanded else {
            print("🧭 [PulseRefresh] refresh blocked: curtain is expanded")
            return
        }
        guard !isMainRefreshing else {
            print("🧭 [PulseRefresh] refresh blocked: already refreshing")
            return
        }
        
        await MainActor.run {
            isMainRefreshing = true
        }
        
        print("🔄 Pull-to-refresh (Главная) started")
        try? await Task.sleep(nanoseconds: 700_000_000)
        print("✅ Pull-to-refresh (Главная) completed")
        
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.18)) {
                isMainRefreshing = false
                mainPullDistance = 0
            }
        }
    }
}

private extension PulseLikeNotificationCenterView {
    var refreshRevealBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : .white
    }
    
    var contentBackgroundStyle: AnyShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(hex: "1C1C1E"),
                        Color(hex: "1C1C1E").opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        
        return AnyShapeStyle(Color.white)
    }
    
    var islandBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : .white
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : .white
    }
    
    var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "333333")
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.65) : Color(hex: "9299A2")
    }
    
    var iconColor: Color {
        colorScheme == .dark ? .white : Color(hex: "333333").opacity(0.6)
    }
    
    var iconBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1)
    }
    
    var closeButtonBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)
    }
    
}

private struct SystemRefreshSpinner: UIViewRepresentable {
    let isAnimating: Bool
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = false
        view.color = UIColor.label.withAlphaComponent(0.75)
        return view
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        if isAnimating {
            uiView.startAnimating()
        } else {
            uiView.stopAnimating()
        }
    }
}

private struct NotificationCardModel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String?
    let iconSystemName: String?
}

private struct ScalePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PulseLikeNotificationCenterView()
    }
}

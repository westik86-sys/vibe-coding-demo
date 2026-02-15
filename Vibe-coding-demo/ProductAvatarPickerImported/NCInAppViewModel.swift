//
//  NCInAppViewModel.swift
//  ProductAvatarPicker
//
//  ViewModel для ЦУ + InApp
//

import SwiftUI
import UIKit
import QuartzCore
import Combine

@MainActor
class NCInAppViewModel: ObservableObject {
    private static let debugLogEnabled = false
    
    // State - ЦУ (Центр уведомлений)
    @Published var isExpanded: Bool = false
    @Published var dragOffset: CGFloat = 0  // Текущее смещение при drag (live)
    @Published var isDragging: Bool = false // Флаг активного drag
    
    // State - InApp
    @Published var isInAppShown: Bool = false
    @Published var isIslandSnapActive: Bool = false
    private var islandFrameInWindow: CGRect = .zero
    
    // InApp components
    private var inAppWindow: InAppWindow?
    private var presentationController: InAppPresentationController?
    private var transition: InAppTransition?
    
    // Константы
    private let collapsedIslandHeight: CGFloat = 108 // Статус бар (~54) + контент (54)
    private let contentVisibleHeight: CGFloat = 110  // Видимая часть "Главной"
    private let gap: CGFloat = 8                     // Просвет между блоками
    
    // Новые параметры для улучшенного UX
    private let snapThreshold: CGFloat = 0.5        // 50% прогресса для snap
    private let velocityThreshold: CGFloat = 800    // Порог скорости для быстрого свайпа
    private let maxDragDistance: CGFloat = 300      // Расстояние для 100% прогресса
    private let rubberBandFactor: CGFloat = 0.3     // Сопротивление для overscroll
    
    // Хаптик feedback - только на пороге принятия решения
    private var hasTriggeredThresholdHaptic = false // Флаг срабатывания порогового хаптика
    
    // MARK: - Computed Properties (Single Source of Truth)
    
    /// Прогресс анимации от 0.0 (collapsed) до 1.0 (expanded)
    private func animationProgress(screenHeight: CGFloat) -> CGFloat {
        // ВАЖНО: учитываем dragOffset даже когда isDragging = false
        // чтобы анимация продолжалась плавно от текущей позиции
        
        let effectiveDrag: CGFloat
        
        if isExpanded {
            // Если развернут - drag up сжимает
            effectiveDrag = -dragOffset
        } else {
            // Если свернут - drag down растягивает
            effectiveDrag = dragOffset
        }
        
        // Нормализуем в диапазон 0...1
        let dragProgress = min(max(effectiveDrag / maxDragDistance, 0), 1)
        
        // Базовый прогресс от состояния
        let baseProgress: CGFloat = isExpanded ? 1.0 : 0.0
        
        // Итоговый прогресс = базовый ± drag offset
        if isExpanded {
            // Если развернут, drag offset вычитается
            return max(0, min(1, baseProgress - dragProgress))
        } else {
            // Если свернут, drag offset добавляется
            return max(0, min(1, baseProgress + dragProgress))
        }
    }
    
    /// Высота острова (интерполируется)
    func islandHeight(screenHeight: CGFloat) -> CGFloat {
        let progress = animationProgress(screenHeight: screenHeight)
        let minHeight = collapsedIslandHeight
        // В развернутом состоянии ЦУ занимает ровно первый вьюпорт
        let maxHeight = screenHeight
        
        return minHeight + (maxHeight - minHeight) * progress
    }
    
    /// Y позиция "Главной" (отступ от верха экрана)
    func contentY(screenHeight: CGFloat) -> CGFloat {
        return islandHeight(screenHeight: screenHeight) + gap
    }
    
    /// Высота "Главной" (интерполируется)
    func contentHeight(screenHeight: CGFloat) -> CGFloat {
        let progress = animationProgress(screenHeight: screenHeight)
        let maxHeight = screenHeight - collapsedIslandHeight - gap
        let minHeight = contentVisibleHeight
        
        return maxHeight - (maxHeight - minHeight) * progress
    }
    
    /// Прозрачность текста "Все уведомления" (исчезает быстро)
    func collapsedTextOpacity(screenHeight: CGFloat) -> CGFloat {
        let progress = animationProgress(screenHeight: screenHeight)
        
        // Исчезает в первые 20% прогресса (быстрое затухание)
        if progress <= 0.2 {
            return 1.0 - (progress / 0.2)
        } else {
            return 0.0
        }
    }
    
    /// Прозрачность текста "Остров" (появляется в конце)
    func expandedTextOpacity(screenHeight: CGFloat) -> CGFloat {
        let progress = animationProgress(screenHeight: screenHeight)
        
        // Появляется в последние 30% прогресса
        if progress >= 0.7 {
            return (progress - 0.7) / 0.3
        } else {
            return 0.0
        }
    }
    
    // MARK: - Public Methods
    
    /// Переключение состояния по тапу
    func toggleExpanded() {
        // Легкий хаптик
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        withAnimation(.timingCurve(0.34, 1.15, 0.25, 1.0, duration: 0.8)) {
            isExpanded.toggle()
            dragOffset = 0
            isDragging = false
        }
        
        let emoji = isExpanded ? "📖" : "📕"
        let status = isExpanded ? "открыт" : "закрыт"
        print("\(emoji) ЦУ+InApp \(status) (тап)")
    }
    
    /// Обработка перетаскивания (жест) - LIVE PREVIEW с пороговым хаптиком
    func handleDrag(translation: CGFloat, screenHeight: CGFloat) {
        isDragging = true
        
        // Определяем эффективный drag с учетом направления
        let effectiveDrag: CGFloat
        
        if isExpanded {
            // Если развернут - drag up сжимает
            if translation < 0 {
                // Нормальное поведение (сжатие)
                effectiveDrag = translation
            } else {
                // Резиновый эффект для обратного направления
                effectiveDrag = translation * rubberBandFactor
            }
        } else {
            // Если свернут - drag down растягивает
            if translation > 0 {
                // Нормальное поведение (растягивание)
                effectiveDrag = translation
            } else {
                // Резиновый эффект для обратного направления
                effectiveDrag = translation * rubberBandFactor
            }
        }
        
        // Применяем rubber band для overscroll (за пределами maxDragDistance)
        if abs(effectiveDrag) > maxDragDistance {
            let overflow = abs(effectiveDrag) - maxDragDistance
            let rubberBandOverflow = overflow * rubberBandFactor
            dragOffset = (effectiveDrag > 0 ? 1 : -1) * (maxDragDistance + rubberBandOverflow)
        } else {
            dragOffset = effectiveDrag
        }
        
        // Вычисляем текущий прогресс
        let currentProgress = animationProgress(screenHeight: screenHeight)
        
        // 🎯 ПОРОГОВЫЙ ХАПТИК - только при пересечении 50%
        // Это момент когда экран "решает" открыться/закрыться
        if !hasTriggeredThresholdHaptic && currentProgress >= snapThreshold {
            // Пересекли порог → хаптик!
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            hasTriggeredThresholdHaptic = true
            print("🎯 Пересечен порог 50% - экран будет открыт")
        } else if hasTriggeredThresholdHaptic && currentProgress < snapThreshold {
            // Вернулись назад за порог → сброс флага
            hasTriggeredThresholdHaptic = false
            print("↩️ Вернулись за порог 50%")
        }
    }
    
    /// Обработка завершения жеста с улучшенной логикой snap
    func handleDragEnd(translation: CGFloat, velocity: CGFloat, screenHeight: CGFloat) {
        // Вычисляем финальный прогресс НА МОМЕНТ отпускания
        let finalProgress = animationProgress(screenHeight: screenHeight)
        
        // Сбрасываем флаги
        hasTriggeredThresholdHaptic = false
        
        // Определяем направление
        let dragDown = translation > 0
        let dragUp = translation < 0
        
        // Проверяем velocity (быстрый свайп)
        let fastDown = velocity > velocityThreshold
        let fastUp = velocity < -velocityThreshold
        
        // Логика принятия решения (с учетом прогресса И velocity)
        let shouldExpand: Bool
        let shouldCollapse: Bool
        
        if isExpanded {
            // Если уже развернут → проверяем нужно ли свернуть
            shouldCollapse = (dragUp && finalProgress < (1.0 - snapThreshold)) || fastUp
            shouldExpand = false
        } else {
            // Если свернут → проверяем нужно ли развернуть
            shouldExpand = (dragDown && finalProgress > snapThreshold) || fastDown
            shouldCollapse = false
        }
        
        // ❌ НЕТ хаптика при отпускании - он уже был при пересечении 50%
        // Это избегает двойного хаптика
        
        // КРИТИЧЕСКИ ВАЖНО: сбрасываем isDragging БЕЗ анимации
        // чтобы избежать скачка, а затем анимируем только изменение состояния
        isDragging = false
        
        // Анимация к финальному состоянию
        withAnimation(.timingCurve(0.34, 1.15, 0.25, 1.0, duration: 0.8)) {
            // Сначала сбрасываем dragOffset
            dragOffset = 0
            
            // Затем меняем состояние (если нужно)
            if shouldExpand {
                isExpanded = true
                print("📖 ЦУ+InApp открыт (progress: \(Int(finalProgress * 100))%, Δ: \(Int(translation))px, v: \(Int(velocity))px/s)")
            } else if shouldCollapse {
                isExpanded = false
                print("📕 ЦУ+InApp закрыт (progress: \(Int(finalProgress * 100))%, Δ: \(Int(translation))px, v: \(Int(velocity))px/s)")
            } else {
                // Возврат к текущему состоянию (только сбрасываем dragOffset)
                print("↩️ Жест отменен (progress: \(Int(finalProgress * 100))%, Δ: \(Int(translation))px, v: \(Int(velocity))px/s)")
            }
        }
    }
    
    // MARK: - InApp Methods
    
    /// Показать/скрыть InApp
    func toggleInApp() {
        if isInAppShown {
            hideInApp()
        } else {
            showInApp()
        }
    }
    
    /// Показать InApp
    func showInApp() {
        debugLog("showInApp() called")
        // Create window if needed
        if inAppWindow == nil {
            setupInAppWindow()
        }
        
        print("🧭 [NCInAppVM] islandFrameInWindow = \(islandFrameInWindow)")
        
        if let transition = transition as? InAppFromNotchTransition,
           !islandFrameInWindow.isEmpty {
            transition.sourceFrameInWindow = islandFrameInWindow
            transition.onSnapStateChanged = { [weak self] isSnapped in
                self?.isIslandSnapActive = isSnapped
            }
            transition.onSnapFinalizeRequested = { [weak self] in
                self?.presentationController?.finalizeAfterSnap()
            }
        }
        
        isIslandSnapActive = false
        isInAppShown = true
        debugLog("isInAppShown = true")
        
        // Create InApp view
        let inAppView = createInAppView()
        
        // Show InApp
        presentationController?.show(inAppView) { [weak self] success in
            if success {
                print("✅ InApp показан успешно")
            } else {
                self?.isInAppShown = false
            }
        }
    }
    
    /// Скрыть InApp
    func hideInApp() {
        debugLog("hideInApp() called")
        if let transition = transition as? InAppFromNotchTransition,
           !islandFrameInWindow.isEmpty {
            transition.sourceFrameInWindow = islandFrameInWindow
        }
        presentationController?.hide { success in
            if success {
                print("✅ InApp скрыт успешно")
            }
        }
    }
    
    // MARK: - InApp Private Setup
    
    private func setupInAppWindow() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            print("⚠️ Не удалось найти активную window scene")
            return
        }
        
        // Create window
        let window = InAppWindow(frame: windowScene.coordinateSpace.bounds)
        window.windowScene = windowScene
        window.isHidden = true
        // Для ЦУ + InApp используем системную тему (не форсим dark)
        window.overrideUserInterfaceStyle = .unspecified
        self.inAppWindow = window
        
        // Create transition
        let transition = InAppFromNotchTransition()
        self.transition = transition
        transition.onSnapStateChanged = { [weak self] isSnapped in
            self?.isIslandSnapActive = isSnapped
        }
        transition.onSnapFinalizeRequested = { [weak self] in
            self?.presentationController?.finalizeAfterSnap()
        }
        
        // Create presentation controller
        let controller = InAppPresentationController(
            inAppWindow: window,
            transition: transition
        )
        controller.delegate = self
        self.presentationController = controller
    }
    
    private func createInAppView() -> UIView {
        // Используем кастомный NCInAppMessageView (изолирован от SimpleInAppView)
        let inAppView = NCInAppMessageView(frame: .zero)
        
        let darkBackgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        let themedBackgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? darkBackgroundColor : .white
        }
        
        inAppView.configure(backgroundColor: themedBackgroundColor)
        
        inAppView.onTap = { [weak self] in
            print("🎯 InApp нажат - выполняем действие")
            self?.hideInApp()
        }
        
        inAppView.onClose = { [weak self] in
            print("❌ Кнопка закрытия нажата")
            self?.hideInApp()
        }
        
        return inAppView
    }
    
    func updateIslandFrame(_ frame: CGRect) {
        guard !frame.isEmpty else { return }
        print("🧭 [NCInAppVM] updateIslandFrame -> \(frame)")
        islandFrameInWindow = frame
    }
}

// MARK: - InAppPresentationControllerDelegate

extension NCInAppViewModel: InAppPresentationControllerDelegate {
    
    func presentationControllerDidShowOffer() {
        print("📱 InApp показан")
    }
    
    func presentationControllerDidHideOffer(isUserInitiated: Bool) {
        print("📱 InApp скрыт (пользователь: \(isUserInitiated))")
        debugLog("presentationControllerDidHideOffer -> isInAppShown = false")
        isIslandSnapActive = false
        isInAppShown = false
    }
    
    func presentationControllerDidOpenOffer() {
        print("📱 InApp открыт (свайп вниз)")
    }
    
    func presentationControllerPanning(inProgress: Bool) {
        if inProgress {
            print("👆 Начало свайпа")
        } else {
            print("👆 Конец свайпа")
        }
    }
    
    func presentationControllerLongPressing(inProgress: Bool) {
        if inProgress {
            print("⏸ Долгое нажатие начато (пауза)")
        } else {
            print("▶️ Долгое нажатие закончено (возобновление)")
        }
    }

    private func debugLog(_ message: String) {
        guard Self.debugLogEnabled else { return }
        let timestamp = String(format: "%.4f", CACurrentMediaTime())
        print("🧭 [NCInAppVM \(timestamp)] \(message)")
    }
    
}

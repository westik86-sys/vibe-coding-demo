//
//  InapViewModel.swift
//  ProductAvatarPicker
//
//  ViewModel for managing InApp presentation
//

import UIKit
import SwiftUI
import Combine

@MainActor
class InapViewModel: ObservableObject {
    
    // InApp components
    private var inAppWindow: InAppWindow?
    private var presentationController: InAppPresentationController?
    private var transition: InAppTransition?
    
    // State
    @Published var isInAppShown: Bool = false
    
    // MARK: - Public Methods
    
    func showInApp() {
        // Toggle logic: если InApp уже показан - скрываем
        if isInAppShown {
            print("🔄 InApp уже показан - скрываем")
            hideInApp()
            return
        }
        
        // Create window if needed
        if inAppWindow == nil {
            setupInAppWindow()
        }
        
        // Create InApp view
        let inAppView = createInAppView()
        
        // Show InApp
        presentationController?.show(inAppView) { [weak self] success in
            if success {
                print("✅ InApp показан успешно")
                self?.isInAppShown = true
            }
        }
    }
    
    // MARK: - Private Setup
    
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
        self.inAppWindow = window
        
        // Create transition
        let transition = InAppFromNotchTransition()
        self.transition = transition
        
        // Create presentation controller
        let controller = InAppPresentationController(
            inAppWindow: window,
            transition: transition
        )
        controller.delegate = self
        self.presentationController = controller
    }
    
    private func createInAppView() -> UIView {
        let inAppView = SimpleInAppView(frame: .zero)
        
        // Random demo colors
        let colors = [
            UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0),  // Синий
            UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0),  // Красный
            UIColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0),  // Зелёный
            UIColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 1.0)   // Фиолетовый
        ]
        
        let randomColor = colors.randomElement()!
        
        inAppView.configure(backgroundColor: randomColor)
        
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
    
    private func hideInApp() {
        presentationController?.hide { [weak self] success in
            if success {
                print("✅ InApp скрыт успешно")
                self?.isInAppShown = false
            }
        }
    }
}

// MARK: - InAppPresentationControllerDelegate

extension InapViewModel: InAppPresentationControllerDelegate {
    
    func presentationControllerDidShowOffer() {
        print("📱 InApp показан")
    }
    
    func presentationControllerDidHideOffer(isUserInitiated: Bool) {
        print("📱 InApp скрыт (пользователь: \(isUserInitiated))")
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
}

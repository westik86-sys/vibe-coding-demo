//
//  InAppWindow.swift
//  ProductAvatarPicker
//
//  Migrated from OffersKit (NOKInAppWindow)
//  Created by t.begishev on 14.09.2022.
//

import UIKit

private final class InAppViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

final class InAppWindow: UIWindow {
    private let inAppViewController = InAppViewController()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @available(*, unavailable)
    override init(windowScene: UIWindowScene) {
        fatalError("Use init(frame:) instead")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(frame:) instead")
    }
    
    // MARK: - Override
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return subviews.first(where: { $0.gestureRecognizers?.isEmpty == false })?.frame.contains(point) == true
    }
    
    // MARK: - Private
    
    private func setupUI() {
        windowLevel = .alert
        backgroundColor = .clear
        overrideUserInterfaceStyle = .dark
        inAppViewController.view.isHidden = true
        inAppViewController.view.backgroundColor = .clear
        rootViewController = inAppViewController
    }
}

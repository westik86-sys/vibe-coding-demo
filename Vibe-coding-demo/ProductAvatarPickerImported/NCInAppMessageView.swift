//
//  NCInAppMessageView.swift
//  ProductAvatarPicker
//
//  Кастомный InApp view для экрана "ЦУ + InApp"
//  (изолирован от оригинального SimpleInAppView)
//

import UIKit

final class NCInAppMessageView: UIView {
    
    // UI Elements
    private let containerView = UIView()
    private let closeButton = UIButton(type: .system)
    
    // Callback
    var onTap: (() -> Void)?
    var onClose: (() -> Void)?
    
    private let lightShadowOpacity: Float = 0.15
    private let lightShadowOffset = CGSize(width: 0, height: 4)
    private let lightShadowRadius: CGFloat = 12
    private let darkBorderWidth: CGFloat = 1
    private let darkBorderAlpha: CGFloat = 0.1
    private var currentBorderAlpha: CGFloat = 0.1
    
    private let darkBackgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
    private let lightIconColor = UIColor.black.withAlphaComponent(0.6)
    private let darkIconColor = UIColor.white
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    
    func configure(backgroundColor: UIColor) {
        containerView.backgroundColor = backgroundColor
    }

    func setCloseButtonAlpha(_ alpha: CGFloat) {
        closeButton.alpha = alpha
    }
    
    func setBorderAlpha(_ alpha: CGFloat) {
        let clamped = min(1, max(0, alpha))
        currentBorderAlpha = clamped
        
        guard traitCollection.userInterfaceStyle == .dark else { return }
        containerView.layer.borderWidth = darkBorderWidth
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(clamped).cgColor
    }
    
    // MARK: - Private Setup
    
    private func setupUI() {
        // Container setup - кастомные размеры для ЦУ + InApp
        containerView.layer.cornerRadius = 32  // Скругления как у острова
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.clipsToBounds = false
        
        // Close button setup
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = currentIconColor()
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(closeButton)
        
        // Setup constraints
        setupConstraints()
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        containerView.addGestureRecognizer(tapGesture)
        
        applyTheme()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyTheme()
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container - кастомная высота для ЦУ + InApp
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 130),  // Больше чем оригинал
            
            // Close button
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    private func currentIconColor() -> UIColor {
        traitCollection.userInterfaceStyle == .dark ? darkIconColor : lightIconColor
    }
    
    private func currentBackgroundColor() -> UIColor {
        traitCollection.userInterfaceStyle == .dark ? darkBackgroundColor : .white
    }
    
    private func applyTheme() {
        closeButton.tintColor = currentIconColor()
        
        if containerView.backgroundColor == .white || containerView.backgroundColor == darkBackgroundColor {
            containerView.backgroundColor = currentBackgroundColor()
        }
        
        if traitCollection.userInterfaceStyle == .dark {
            containerView.layer.shadowOpacity = 0
            containerView.layer.shadowOffset = .zero
            containerView.layer.shadowRadius = 0
            containerView.layer.borderWidth = darkBorderWidth
            containerView.layer.borderColor = UIColor.white.withAlphaComponent(currentBorderAlpha).cgColor
        } else {
            containerView.layer.shadowOpacity = lightShadowOpacity
            containerView.layer.shadowOffset = lightShadowOffset
            containerView.layer.shadowRadius = lightShadowRadius
            containerView.layer.borderWidth = 0
            containerView.layer.borderColor = nil
        }
    }
    
    // MARK: - Actions
    
    @objc private func viewTapped() {
        onTap?()
    }
    
    @objc private func closeButtonTapped() {
        onClose?()
    }
}

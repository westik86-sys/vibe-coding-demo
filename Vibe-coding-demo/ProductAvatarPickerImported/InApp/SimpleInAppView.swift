//
//  SimpleInAppView.swift
//  ProductAvatarPicker
//
//  Simple InApp message view for demonstration
//

import UIKit

final class SimpleInAppView: UIView {
    
    // UI Elements
    private let containerView = UIView()
    private let closeButton = UIButton(type: .system)
    
    // Callback
    var onTap: (() -> Void)?
    var onClose: (() -> Void)?
    
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
    
    // MARK: - Private Setup
    
    private func setupUI() {
        // Container setup
        containerView.layer.cornerRadius = 24
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.15
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 12
        containerView.clipsToBounds = false
        
        // Close button setup
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white.withAlphaComponent(0.8)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(closeButton)
        
        // Setup constraints
        setupConstraints()
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        containerView.addGestureRecognizer(tapGesture)
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 120),
            
            // Close button
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func viewTapped() {
        onTap?()
    }
    
    @objc private func closeButtonTapped() {
        onClose?()
    }
}

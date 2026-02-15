//
//  BenefitsMainBackgroundView.swift
//  TBenefits
//
//  Created by Nikita Andrienko on 10.05.24.
//

import SwiftUI
import UIKit

private enum Constants {
    static let noiseEffectHeightRatio: CGFloat = 0.6
    static let bottomBackgroundOffset: CGFloat = 52
    static let noiseImageAlpha: CGFloat = 0.7
}

struct BenefitsMainBackground: UIViewRepresentable {
    
    func makeUIView(context: Context) -> BenefitsMainBackgroundView {
        let view = BenefitsMainBackgroundView()
        view.startWavesAnimation()
        return view
    }
    
    func updateUIView(_ uiView: BenefitsMainBackgroundView, context: Context) {
    }
}

/// Вью для фона главного экрана выгоды,
/// состоит из волн с добавлением шума и градиента
final class BenefitsMainBackgroundView: UIView {

    // UI
    private let noiseImageView: UIImageView = {
        let imageView = UIImageView(image: .noiseBg)
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = Constants.noiseImageAlpha
        return imageView
    }()

    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.Background.accentOnLight
        return view
    }()

    private let animatedWavesView = AnimatedWavesView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError(file: "", line: 0)
    }

    // MARK: - Public

    func startWavesAnimation() {
        animatedWavesView.startAnimation()
    }

    func stopWavesAnimation() {
        animatedWavesView.stopAnimation()
    }
}

// MARK: - Private

private extension BenefitsMainBackgroundView {

    func setupUI() {
        addSubviews()
        makeConstraints()
    }

    func addSubviews() {
        addSubview(backgroundView)
        addSubview(animatedWavesView)
//        addSubview(gradientView)
        addSubview(noiseImageView)
    }

    func makeConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        animatedWavesView.translatesAutoresizingMaskIntoConstraints = false
        noiseImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // backgroundView
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // animatedWavesView
            animatedWavesView.leadingAnchor.constraint(equalTo: leadingAnchor),
            animatedWavesView.trailingAnchor.constraint(equalTo: trailingAnchor),
            animatedWavesView.topAnchor.constraint(equalTo: topAnchor),
            animatedWavesView.heightAnchor.constraint(equalTo: heightAnchor, constant: -Constants.bottomBackgroundOffset),
            
            // noiseImageView
            noiseImageView.leadingAnchor.constraint(equalTo: animatedWavesView.leadingAnchor),
            noiseImageView.trailingAnchor.constraint(equalTo: animatedWavesView.trailingAnchor),
            noiseImageView.topAnchor.constraint(equalTo: animatedWavesView.topAnchor),
            noiseImageView.heightAnchor.constraint(equalTo: animatedWavesView.heightAnchor, multiplier: Constants.noiseEffectHeightRatio)
        ])
    }
}

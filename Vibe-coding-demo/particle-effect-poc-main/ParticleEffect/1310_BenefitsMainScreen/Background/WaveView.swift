//
//  WaveView.swift
//  TBenefits
//
//  Created by Nikita Andrienko on 9.05.24.
//

import UIKit

private extension CGFloat {
    static let wavesColorAlpha: CGFloat = 0.1
    static let waveShadowRadius: CGFloat = 55
}

/// Градиентная волна, используется для анимаций фона выгоды
final class WaveView: UIView {

    private let gradientView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.autoresizingMask = UIView.AutoresizingMask(
            rawValue: UIView.AutoresizingMask.flexibleWidth.rawValue | UIView.AutoresizingMask.flexibleHeight.rawValue
        )
        return view
    }()

    /// Радиус скругления волны
    private var waveCornerRadius: CGFloat {
        bounds.width / 2
    }

    // MARK: - Init

    init(frame: CGRect, color: UIColor) {
        super.init(frame: frame)

        setupUI()
        setupGradientLayer(with: color)
        setupShadow(with: color)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError(file: "", line: 0)
    }

    // MARK: - TinyMachO binary masking support

    @available(*, unavailable)
    override init(frame: CGRect) {
        fatalError(file: "", line: 0)
    }

    // MARK: - Public

    func setColor(_ color: UIColor) {
        layer.shadowColor = color.cgColor
        setupGradientLayer(with: color)
    }
}

// MARK: - Private

private extension WaveView {

    func setupUI() {
        addSubviews()
        makeConstraints()

        gradientView.layer.cornerRadius = waveCornerRadius
        backgroundColor = .clear
    }

    func addSubviews() {
        addSubview(gradientView)
    }

    func makeConstraints() {
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor),
            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func setupShadow(with color: UIColor) {
        layer.shadowColor = color.cgColor
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shadowOpacity = 0.8
        layer.shadowRadius = .waveShadowRadius
    }

    func setupGradientLayer(with color: UIColor) {
        let gradientLayerMask = CAGradientLayer()
        gradientLayerMask.frame = bounds
        gradientLayerMask.colors = [
            color.withAlphaComponent(.wavesColorAlpha).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayerMask.startPoint = .zero
        gradientLayerMask.endPoint = CGPoint(x: 1, y: 1)
        gradientLayerMask.type = .radial

        gradientView.layer.mask = gradientLayerMask
    }
}

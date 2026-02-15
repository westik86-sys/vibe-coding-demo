//
//  BenefitAnimatedWavesView.swift
//  TBenefits
//
//  Created by Nikita Andrienko on 16.11.23.
//

import UIKit

private enum Constants {
    static let wavesAnimationDuration: TimeInterval = 10
}

/// Конфигурация задающая цвета волнам
struct WavesColorsAppearance {
    static let `default` = WavesColorsAppearance(
        rightDarkWaveColor: UIColor.waveDefaultSecondary,
        rightLightWaveColor: UIColor.waveDefaultPrimary,
        leftWaveColor: UIColor.waveDefaultPrimary,
        backgroundColor: UIColor.Background.accentOnLight
    )

    let rightDarkWaveColor: UIColor
    let rightLightWaveColor: UIColor
    let leftWaveColor: UIColor
    let backgroundColor: UIColor
}

enum AnimatedWavesState {
    case layoutNotConfigured
    case layoutConfigured
    case animationInProgress
    case animationInterrupted
}

final class AnimatedWavesView: UIView {
    /// Высота волны
    private var waveHeight: CGFloat {
        frame.height / 2.1
    }
    /// Ширина волны
    private var waveWidth: CGFloat {
        frame.width / 4
    }
    /// Cтартовое положение правых волн по x
    private var rightWaveOriginX: CGFloat {
        frame.width - (waveWidth / 2)
    }
    /// Стартовое положение левых волн по x
    private let leftWaveOriginX: CGFloat = .zero
    /// Стартовое положение волн по y
    private let waveOriginY: CGFloat = -40
    /// Угол наклона волн
    private let waveRotationAngle = (5 * CGFloat.pi / 6)

    private var wavesAppearance: WavesColorsAppearance = .default
    private var wavesState: AnimatedWavesState = .layoutNotConfigured

    // Views
    private var rightLightWaveView: WaveView?
    private var rightDarkWaveView: WaveView?
    private var leftWaveView: WaveView?

    // MARK: - Overrides
    
    override func layoutSubviews() {
        setupLayout()
    }
}

// MARK: - Public methods

extension AnimatedWavesView {

    func configureAppearance(_ appearance: WavesColorsAppearance) {
        guard let leftWaveView,
              let rightDarkWaveView,
              let rightLightWaveView
        else {
            wavesAppearance = appearance
            return
        }

        func updateAppearance(with appearance: WavesColorsAppearance) {
            leftWaveView.setColor(appearance.leftWaveColor)
            rightDarkWaveView.setColor(appearance.rightDarkWaveColor)
            rightLightWaveView.setColor(appearance.rightLightWaveColor)
        }

        UIView.animate(withDuration: 0.2) {
            updateAppearance(with: appearance)
        }
    }

    func stopAnimation() {
        guard wavesState == .animationInProgress else { return }

        rightLightWaveView?.layer.removeAllAnimations()
        rightDarkWaveView?.layer.removeAllAnimations()
        leftWaveView?.layer.removeAllAnimations()

        wavesState = .animationInterrupted
    }

    func startAnimation() {
        guard ![.animationInProgress, .layoutNotConfigured].contains(wavesState),
              let rightDarkWaveView,
              let rightLightWaveView,
              let leftWaveView
        else {
            return
        }

        wavesState = .animationInProgress

        let wavesMovementAnimation = {
            let rightWaveCenter = rightLightWaveView.center
            let leftWaveCenter = leftWaveView.center
            let secondLeftWaveCenter = CGPoint(
                x: (leftWaveCenter.x - self.waveWidth),
                y: leftWaveCenter.y
            )

            rightLightWaveView.center = leftWaveCenter
            rightDarkWaveView.center = secondLeftWaveCenter
            leftWaveView.center = rightWaveCenter
        }

        UIView.animate(
            withDuration: Constants.wavesAnimationDuration,
            delay: 0,
            options: [.curveEaseInOut, .repeat, .autoreverse],
            animations: wavesMovementAnimation,
            completion: { _ in
                self.wavesState = .animationInterrupted
            }
        )
    }
}

// MARK: - Private

private extension AnimatedWavesView {

    func setupLayout() {
        guard wavesState == .layoutNotConfigured else { return }
        setupWaves()
        wavesState = .layoutConfigured
    }

    func setupWaves() {
        clipsToBounds = true

        // Настраиваем правую волну
        rightLightWaveView = WaveView(
            frame: CGRect(
                x: rightWaveOriginX,
                y: waveOriginY,
                width: waveWidth,
                height: waveHeight
            ),
            color: wavesAppearance.rightLightWaveColor
        )

        // Настраиваем вторую правую волну
        rightDarkWaveView = WaveView(
            frame: CGRect(
                x: rightWaveOriginX - waveWidth,
                y: waveOriginY,
                width: waveWidth,
                height: waveHeight
            ),
            color: wavesAppearance.rightDarkWaveColor
        )

        // Настраиваем левую волну
        leftWaveView = WaveView(
            frame: CGRect(
                x: leftWaveOriginX,
                y: waveOriginY,
                width: waveWidth,
                height: waveHeight
            ),
            color: wavesAppearance.leftWaveColor
        )

        guard let leftWaveView,
              let rightDarkWaveView,
              let rightLightWaveView
        else {
            return
        }

        addSubview(rightLightWaveView)
        addSubview(rightDarkWaveView)
        addSubview(leftWaveView)

        // Задаем наклон волнам
        leftWaveView.transform = CGAffineTransformMakeRotation(waveRotationAngle)
        rightLightWaveView.transform = CGAffineTransformMakeRotation(waveRotationAngle)
        rightDarkWaveView.transform = CGAffineTransformMakeRotation(waveRotationAngle)
    }
}

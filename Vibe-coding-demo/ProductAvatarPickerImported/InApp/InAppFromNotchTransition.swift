
//
//  InAppFromNotchTransition.swift
//  ProductAvatarPicker
//
//  Migrated from OffersKit
//  Created by Timur Begishev on 12.09.2024.
//

import Foundation
import UIKit
import QuartzCore

private extension TimeInterval {
    static let appearingTransitionDuration: TimeInterval = 0.7
    static let hidingTransitionDuration: TimeInterval = 0.3
}

private extension CGFloat {
    static let offerOffscreenOffset: CGFloat = -180
    static let offerBaseAlpha: CGFloat = 0.5
    static let baseStateScaleFactor: CGFloat = 0.75
    static let morphDragDistance: CGFloat = 120
}

final class InAppFromNotchTransition: InAppTransition {
    
    // Private
    private var view: UIView? {
        animatableComponents.first
    }
    
    var sourceFrameInWindow: CGRect?
    var hideDurationOverride: TimeInterval?
    
    private var viewHeight: CGFloat {
        return (view?.bounds.height).unwrapped(or: .zero)
    }
    private var hasTriggeredSnapHaptic = false
    private var isSnapLatched = false
    private var baseFrameInSuperview: CGRect?
    private var lastCurrentTop: CGFloat?
    var onSnapStateChanged: ((Bool) -> Void)?
    var onSnapFinalizeRequested: (() -> Void)?
    var hasSnapped: Bool { hasTriggeredSnapHaptic }
    
    func resetSnapState() {
        hasTriggeredSnapHaptic = false
        isSnapLatched = false
        baseFrameInSuperview = nil
        lastCurrentTop = nil
    }
    private static let debugLogEnabled = false
    private static let morphLogEnabled = false
    private static let snapLogEnabled = true
    
    // MARK: - InAppTransition
    
    var animatableComponents: [UIView] = []
    
    func startAppearingAnimation(_ completion: @escaping (() -> Void)) {
        resetSnapState()
        let animator = startAppearingAnimationWithAnimator()
        animator.addCompletion { _ in completion() }
        animator.startAnimation()
    }

    func startAppearingAnimationWithAnimator() -> UIViewPropertyAnimator {
        guard let view = view else {
            return UIViewPropertyAnimator(duration: 0, curve: .linear)
        }
        
        debugLog("startAppearingAnimation")
        view.superview?.layoutIfNeeded()
        
        if let sourceFrame = sourceFrameInWindow,
           !sourceFrame.isEmpty,
           view.bounds.width > 0,
           view.bounds.height > 0 {
            view.applyMorphBaseState(from: sourceFrame)
        } else {
            view.toBaseState()
        }
        updateCloseButtonAlpha(progress: 0)
        setBorderAlpha(0)
        let animator = UIViewPropertyAnimator(
            duration: .appearingTransitionDuration,
            controlPoint1: CGPoint(x: 0.35, y: 1.3),
            controlPoint2: CGPoint(x: 0.25, y: 1)
        ) { [weak view] in
            view?.transform = .identity
            view?.alpha = 1
        }
        addBorderFadeIn(to: animator)
        return animator
    }
    
    func startDisappearingAnimation(_ completion: @escaping (() -> Void)) {
        guard let view = view else {
            completion()
            return
        }
        
        debugLog("startDisappearingAnimation")
        view.superview?.layoutIfNeeded()
        let targetTransform = view.morphTargetTransform(sourceFrameInWindow: sourceFrameInWindow)
        
        let duration = hideDurationOverride ?? .hidingTransitionDuration
        hideDurationOverride = nil
        updateCloseButtonAlpha(progress: 0)
        setBorderAlpha(0.1)
        let animator = UIViewPropertyAnimator(
            duration: duration,
            controlPoint1: CGPoint(x: 0.4, y: 0),
            controlPoint2: CGPoint(x: 1, y: 1)
        ) { [weak view] in
            view?.transform = targetTransform
            view?.alpha = 1
        }
        addCloseButtonFade(to: animator)
        addBorderFadeOut(to: animator)
        animator.addCompletion { _ in completion() }
        animator.startAnimation()
    }

    func animateToMorphTarget(duration: TimeInterval, completion: @escaping (() -> Void)) {
        guard let view = view else {
            completion()
            return
        }
        
        debugLog("animateToMorphTarget duration=\(duration)")
        view.superview?.layoutIfNeeded()
        let targetTransform = view.morphTargetTransform(sourceFrameInWindow: sourceFrameInWindow)
        updateCloseButtonAlpha(progress: 0)
        setBorderAlpha(0.1)
        let animator = UIViewPropertyAnimator(
            duration: duration,
            controlPoint1: CGPoint(x: 0.4, y: 0),
            controlPoint2: CGPoint(x: 1, y: 1)
        ) { [weak view] in
            view?.transform = targetTransform
            view?.alpha = 1
        }
        addCloseButtonFade(to: animator)
        addBorderFadeOut(to: animator)
        animator.addCompletion { _ in completion() }
        animator.startAnimation()
    }
    
    func performChanges(with translation: CGPoint, animated: Bool, completion: (() -> Void)?) {
        let changesBlock: () -> Void = { [weak view] in
            let yTranslation = translation.y >= 14
                ? 14 * (1 + log10(translation.y / 14))
                : translation.y
            let translationTransform = CGAffineTransform(
                translationX: .zero,
                y: yTranslation
            )
            view?.transform = {
                if yTranslation < 0, let sourceFrame = self.sourceFrameInWindow, let view = view {
                    if self.baseFrameInSuperview == nil {
                        self.baseFrameInSuperview = view.frame
                    }
                    let progressInfo = self.morphProgress(
                        for: sourceFrame,
                        in: view,
                        translationY: yTranslation
                    )
                    let sourceInSuperview = view.superview?.convert(sourceFrame, from: nil) ?? sourceFrame
                    let targetTransform = view.morphTransform(
                        sourceInSuperview: sourceInSuperview,
                        targetFrame: self.baseFrameInSuperview ?? view.frame
                    )
                    self.updateCloseButtonAlpha(progress: progressInfo.progress)
                    self.updateBorderAlpha(progress: progressInfo.progress)
                    var transform = CGAffineTransform.interpolate(
                        from: .identity,
                        to: targetTransform,
                        progress: progressInfo.progress
                    )
                    let followFactor = 0.35 * (1 - min(1, progressInfo.progress))
                    if followFactor > 0 {
                        transform = transform.concatenating(
                            CGAffineTransform(translationX: 0, y: yTranslation * followFactor)
                        )
                    }
                    let currentFrame = (self.baseFrameInSuperview ?? view.frame).applying(transform)
                    self.updateSnapHaptic(currentFrame: currentFrame, sourceFrame: sourceInSuperview)
                    if progressInfo.extraTranslation > 6 {
                        transform = transform.translatedBy(x: 0, y: -progressInfo.extraTranslation * 0.2)
                    }
                    self.debugProgressLog(
                        progressInfo: progressInfo,
                        baseFrame: self.baseFrameInSuperview,
                        currentFrame: currentFrame,
                        sourceFrame: sourceInSuperview
                    )
                    return transform
                }
                if yTranslation < 0 {
                    let multiplier = -yTranslation / 150
                    let progress = min(1, max(0, -yTranslation / .morphDragDistance))
                    self.updateBorderAlpha(progress: progress)
                    let scaleFactor = 1 - (1 - CGFloat.baseStateScaleFactor) * multiplier
                    let scaling = CGAffineTransform(
                        scaleX: scaleFactor,
                        y: scaleFactor
                    )
                    return scaling.concatenating(translationTransform)
                }
                if yTranslation > 0 {
                    // Вариант A: легкий "squash" при усилии вниз
                    let effort = min(1, yTranslation / 40)
                    let scaleY = 1 - (0.04 * effort)
                    let scaleX = 1 - (0.012 * effort)
                    let squash = CGAffineTransform(scaleX: scaleX, y: scaleY)
                    return squash.concatenating(translationTransform)
                }
                self.baseFrameInSuperview = nil
                self.lastCurrentTop = nil
                self.isSnapLatched = false
                self.updateCloseButtonAlpha(progress: 0)
                self.setBorderAlpha(0.1)
                return translationTransform
            }()
        }
        if animated {
            let animator = UIViewPropertyAnimator(
                duration: .hidingTransitionDuration,
                curve: .easeInOut,
                animations: changesBlock
            )
            animator.addCompletion { _ in completion?() }
            animator.startAnimation()
        } else {
            changesBlock()
            completion?()
        }
    }
    
    func isHidingNeeded(with translation: CGPoint) -> Bool {
        return -translation.y > 24
    }
    
    func isOpeningNeeded(with translation: CGPoint) -> Bool {
        return false
    }

    private func debugLog(_ message: String) {
        guard Self.debugLogEnabled else { return }
        let timestamp = String(format: "%.4f", CACurrentMediaTime())
        print("🧭 [InAppTransition \(timestamp)] \(message)")
    }
}

// MARK: - Private

private extension InAppFromNotchTransition {
    func morphProgress(for sourceFrame: CGRect, in view: UIView, translationY: CGFloat) -> (progress: CGFloat, extraTranslation: CGFloat) {
        guard let baseFrame = baseFrameInSuperview, let superview = view.superview else {
            let rawProgress = -translationY / .morphDragDistance
            return (min(1, max(0, rawProgress)), max(0, -translationY - .morphDragDistance))
        }
        let sourceInSuperview = superview.convert(sourceFrame, from: nil)
        let totalDistance = max(abs(baseFrame.midY - sourceInSuperview.midY), 1)
        let rawProgress = -translationY / totalDistance
        let progress = min(1, max(0, rawProgress))
        let extra = max(0, -translationY - totalDistance)
        return (progress, extra)
    }
    
    func updateSnapHaptic(currentFrame: CGRect, sourceFrame: CGRect) {
        let currentTop = currentFrame.minY
        let sourceTop = sourceFrame.minY
        let currentHeight = currentFrame.height
        let sourceHeight = sourceFrame.height
        // Вариант 2: считаем виртуальный targetTop для совпадения по нижней границе
        let targetTop = sourceTop + (sourceHeight - currentHeight)
        let deltaTop = abs(currentTop - targetTop)
        let crossed = (lastCurrentTop ?? currentTop) > targetTop && currentTop <= targetTop
        lastCurrentTop = currentTop
        if Self.snapLogEnabled {
            let message = String(
                format: "top: cur=%.1f tgt=%.1f Δ=%.1f | h: cur=%.1f src=%.1f | crossed=%@",
                currentTop,
                targetTop,
                deltaTop,
                currentHeight,
                sourceHeight,
                crossed.description
            )
            print("🧭 [InAppSnap] \(message)")
        }
        if (deltaTop <= 2 || crossed), !hasTriggeredSnapHaptic {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            hasTriggeredSnapHaptic = true
            isSnapLatched = true
            onSnapStateChanged?(true)
            onSnapFinalizeRequested?()
            if Self.snapLogEnabled {
                print("🧭 [InAppSnap] snapped=true")
            }
        } else if deltaTop > 2, hasTriggeredSnapHaptic, !isSnapLatched {
            hasTriggeredSnapHaptic = false
            onSnapStateChanged?(false)
            if Self.snapLogEnabled {
                print("🧭 [InAppSnap] snapped=false")
            }
        }
    }

    func updateCloseButtonAlpha(progress: CGFloat) {
        guard let messageView = view as? NCInAppMessageView else { return }
        let clamped = min(1, max(0, progress))
        let alpha: CGFloat
        if clamped <= 0.5 {
            alpha = 1
        } else {
            alpha = 1 - ((clamped - 0.5) / 0.5)
        }
        messageView.setCloseButtonAlpha(alpha)
    }
    
    func setBorderAlpha(_ alpha: CGFloat) {
        guard let messageView = view as? NCInAppMessageView else { return }
        messageView.setBorderAlpha(alpha)
    }
    
    func updateBorderAlpha(progress: CGFloat) {
        let clamped = min(1, max(0, progress))
        let alpha = 0.1 * (1 - clamped)
        setBorderAlpha(alpha)
    }
    
    func addCloseButtonFade(to animator: UIViewPropertyAnimator) {
        guard let messageView = view as? NCInAppMessageView else { return }
        animator.addAnimations({
            messageView.setCloseButtonAlpha(0)
        }, delayFactor: 0.5)
    }
    
    func addBorderFadeIn(to animator: UIViewPropertyAnimator) {
        guard view is NCInAppMessageView else { return }
        animator.addAnimations({
            self.setBorderAlpha(0.1)
        })
    }
    
    func addBorderFadeOut(to animator: UIViewPropertyAnimator) {
        guard view is NCInAppMessageView else { return }
        animator.addAnimations({
            self.setBorderAlpha(0)
        })
    }

    func debugProgressLog(
        progressInfo: (progress: CGFloat, extraTranslation: CGFloat),
        baseFrame: CGRect?,
        currentFrame: CGRect,
        sourceFrame: CGRect
    ) {
        guard Self.morphLogEnabled else { return }
        let baseTop = baseFrame?.minY ?? 0
        let totalDistance = max(abs((baseFrame?.midY ?? 0) - sourceFrame.midY), 0)
        let remaining = max(0, totalDistance * (1 - progressInfo.progress))
        let message = String(
            format: "progress=%.3f extra=%.1f total=%.1f remaining=%.1f baseTop=%.1f currentTop=%.1f sourceTop=%.1f",
            progressInfo.progress,
            progressInfo.extraTranslation,
            totalDistance,
            remaining,
            baseTop,
            currentFrame.minY,
            sourceFrame.minY
        )
        print("🧭 [InAppMorph] \(message)")
    }
}

private extension UIView {
    func morphTargetTransform(sourceFrameInWindow: CGRect?) -> CGAffineTransform {
        guard let sourceFrame = sourceFrameInWindow, !sourceFrame.isEmpty else {
            return baseStateTransform()
        }
        return morphTransform(from: sourceFrame)
    }
    
    func toBaseState() {
        self.transform = baseStateTransform()
        alpha = .offerBaseAlpha
    }
    
    func applyMorphBaseState(from sourceFrame: CGRect) {
        guard let superview = superview else {
            toBaseState()
            return
        }
        let sourceInSuperview = superview.convert(sourceFrame, from: nil)
        let targetFrame = superview.convert(frame, from: superview)
        
        guard targetFrame.width > 0, targetFrame.height > 0 else {
            toBaseState()
            return
        }
        self.transform = morphTransform(
            sourceInSuperview: sourceInSuperview,
            targetFrame: targetFrame
        )
        alpha = 1
    }
    
    func morphTransform(from sourceFrame: CGRect) -> CGAffineTransform {
        guard let superview = superview else {
            return baseStateTransform()
        }
        let sourceInSuperview = superview.convert(sourceFrame, from: nil)
        let targetFrame = superview.convert(frame, from: superview)
        return morphTransform(sourceInSuperview: sourceInSuperview, targetFrame: targetFrame)
    }
    
    func morphTransform(sourceInSuperview: CGRect, targetFrame: CGRect) -> CGAffineTransform {
        guard targetFrame.width > 0, targetFrame.height > 0 else {
            return baseStateTransform()
        }
        
        let scaleX = sourceInSuperview.width / targetFrame.width
        let scaleY = sourceInSuperview.height / targetFrame.height
        let targetCenter = CGPoint(x: targetFrame.midX, y: targetFrame.midY)
        let sourceCenter = CGPoint(x: sourceInSuperview.midX, y: sourceInSuperview.midY)
        let dx = sourceCenter.x - targetCenter.x
        let dy = sourceCenter.y - targetCenter.y
        
        var transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        transform = transform.translatedBy(x: dx / scaleX, y: dy / scaleY)
        return transform
    }
    
    func baseStateTransform() -> CGAffineTransform {
        let translation = CGAffineTransform(
            translationX: .zero,
            y: .offerOffscreenOffset
        )
        let scaling = CGAffineTransform(
            scaleX: .baseStateScaleFactor,
            y: .baseStateScaleFactor
        )
        return scaling.concatenating(translation)
    }
}

private extension CGAffineTransform {
    static func interpolate(from: CGAffineTransform, to: CGAffineTransform, progress: CGFloat) -> CGAffineTransform {
        let t = min(1, max(0, progress))
        return CGAffineTransform(
            a: from.a + (to.a - from.a) * t,
            b: from.b + (to.b - from.b) * t,
            c: from.c + (to.c - from.c) * t,
            d: from.d + (to.d - from.d) * t,
            tx: from.tx + (to.tx - from.tx) * t,
            ty: from.ty + (to.ty - from.ty) * t
        )
    }
}

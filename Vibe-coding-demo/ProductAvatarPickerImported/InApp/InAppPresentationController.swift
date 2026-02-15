//
//  InAppPresentationController.swift
//  ProductAvatarPicker
//
//  Migrated from OffersKit (NOKInAppPresentationController)
//  Created by t.begishev on 12.08.2022.
//

import UIKit
import QuartzCore

protocol InAppPresentationControllerDelegate: AnyObject {
    func presentationControllerDidShowOffer()
    func presentationControllerDidHideOffer(isUserInitiated: Bool)
    func presentationControllerDidOpenOffer()
    func presentationControllerPanning(inProgress: Bool)
    func presentationControllerLongPressing(inProgress: Bool)
}

private extension CGFloat {
    static let topOffset: CGFloat = 20
}

final class InAppPresentationController: NSObject, UIGestureRecognizerDelegate {
    private static let debugLogEnabled = false
    private enum PresentationState {
        case idle
        case presenting
        case presented
        case dismissing
    }
    
    private var state: PresentationState = .idle
    private var presentingAnimator: UIViewPropertyAnimator?
    private var cleanupDisplayLink: CADisplayLink?
    private var pendingCleanupFrames: Int = 0
    private var pendingCleanup: (() -> Void)?
    
    // Dependencies
    private let transition: InAppTransition
    weak var delegate: InAppPresentationControllerDelegate?
    
    // UI
    private var contentView: UIView?
    private let inAppWindow: InAppWindow
    private lazy var panGestureRecognizer = UIPanGestureRecognizer(
        target: self,
        action: #selector(handlePanGesture)
    )
    private lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPressGesture)
        )
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = self
        return recognizer
    }()
    
    // MARK: - Initialization
    
    init(
        inAppWindow: InAppWindow,
        transition: InAppTransition
    ) {
        self.inAppWindow = inAppWindow
        self.transition = transition
    }
    
    // MARK: - Public Methods
    
    func show(_ view: UIView, completion: ((Bool) -> Void)?) {
        contentView = view
        inAppWindow.addSubview(view)
        setupConstraints(
            in: inAppWindow,
            topAnchorConstant: inAppWindow.statusBarHeight + .topOffset
        )
        if let morphTransition = transition as? InAppFromNotchTransition {
            morphTransition.resetSnapState()
        }
        for recognizer in [longPressGestureRecognizer, panGestureRecognizer] {
            recognizer.isEnabled = true
            view.addGestureRecognizer(recognizer)
        }
        debugLog("show() -> presentInApp")
        presentInApp(completion)
    }
    
    func hide(completion: ((Bool) -> Void)?) {
        debugLog("hide() requested")
        if state == .presenting {
            debugLog("hide() during presenting -> cancel present animation")
            presentingAnimator?.stopAnimation(true)
            presentingAnimator?.finishAnimation(at: .current)
        }
        state = .dismissing
        contentView?.isUserInteractionEnabled = false
        for recognizer in (contentView?.gestureRecognizers).unwrapped(or: []) {
            recognizer.isEnabled = false
        }
        
        // Small delay before starting hide animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else {
                completion?(false)
                return
            }
            self.debugLog("hide() -> completeHide")
            self.completeHide(isUserInitiated: false, durationOverride: nil, completion: completion)
        }
    }

    func finalizeAfterSnap() {
        debugLog("finalizeAfterSnap()")
        panGestureRecognizer.isEnabled = false
        finalizeHide(isUserInitiated: true, completion: nil)
    }
    
    // MARK: - Private UIPanGestureRecognizer
    
    @objc
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let view = contentView else { return }
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .began, .changed:
            if transition.isOpeningNeeded(with: translation) {
                contentView?.removeGestureRecognizer(panGestureRecognizer)
                delegate?.presentationControllerDidOpenOffer()
            } else {
                transition.performChanges(with: translation, animated: false)
                if gesture.state == .began {
                    delegate?.presentationControllerPanning(inProgress: true)
                }
            }
        case .cancelled, .ended:
            panningEnded(with: translation, velocity: gesture.velocity(in: view))
        default:
            break
        }
    }
    
    private func panningEnded(with translation: CGPoint, velocity: CGPoint) {
        if transition.isHidingNeeded(with: translation) {
            if let morphTransition = transition as? InAppFromNotchTransition {
                let log = "hasSnapped=\(morphTransition.hasSnapped) velocityY=\(velocity.y)"
                print("🧭 [InAppPanEnd] \(log)")
            }
            if let morphTransition = transition as? InAppFromNotchTransition,
               morphTransition.hasSnapped {
                finalizeHide(isUserInitiated: true, completion: nil)
                return
            }
            if transition is InAppFromNotchTransition {
                let speed = max(0, -velocity.y)
                let duration: TimeInterval
                if speed <= 300 {
                    duration = 0.3
                } else {
                    let normalized = min(1, (speed - 300) / 1200)
                    duration = 0.3 - (0.12 * normalized)
                }
                completeHide(isUserInitiated: true, durationOverride: duration, completion: nil)
            } else {
                completeHide(isUserInitiated: true, durationOverride: nil, completion: nil)
            }
        } else {
            transition.performChanges(with: .zero, animated: true)
            delegate?.presentationControllerPanning(inProgress: false)
        }
    }
    
    // MARK: - Private UILongPressGestureRecognizer
    
    @objc
    private func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            delegate?.presentationControllerLongPressing(inProgress: true)
        case .cancelled, .ended:
            delegate?.presentationControllerLongPressing(inProgress: false)
        default:
            break
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
    
    // MARK: - Private
    
    private func setupConstraints(in targetView: UIView, topAnchorConstant: CGFloat) {
        guard let view = contentView else { return }
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: targetView.leadingAnchor, constant: 8),
            view.trailingAnchor.constraint(equalTo: targetView.trailingAnchor, constant: -8),
            view.topAnchor.constraint(equalTo: targetView.topAnchor, constant: topAnchorConstant)
        ])
    }
    
    private func presentInApp(_ completion: ((Bool) -> Void)?) {
        guard let view = contentView else {
            inAppWindow.isHidden = true
            completion?(false)
            return
        }
        inAppWindow.isHidden = false
        state = .presenting
        transition.animatableComponents = [view]
        debugLog("presentInApp() -> startAppearingAnimation")
        if let morphTransition = transition as? InAppFromNotchTransition {
            let animator = morphTransition.startAppearingAnimationWithAnimator()
            animator.addCompletion { [weak self, weak delegate] _ in
                guard let self = self else { return }
                self.debugLog("presentInApp() completion")
                if self.state == .presenting {
                    self.state = .presented
                    delegate?.presentationControllerDidShowOffer()
                    completion?(true)
                }
            }
            presentingAnimator = animator
            animator.startAnimation()
        } else {
            transition.startAppearingAnimation { [weak self, weak delegate] in
                guard let self = self else { return }
                self.debugLog("presentInApp() completion")
                if self.state == .presenting {
                    self.state = .presented
                    delegate?.presentationControllerDidShowOffer()
                    completion?(true)
                }
            }
        }
    }
    
    private func completeHide(isUserInitiated: Bool, durationOverride: TimeInterval?, completion: ((Bool) -> Void)?) {
        if let morphTransition = transition as? InAppFromNotchTransition,
           let durationOverride {
            debugLog("completeHide() -> animateToMorphTarget")
            morphTransition.animateToMorphTarget(duration: durationOverride) { [weak self] in
                self?.finalizeHide(isUserInitiated: isUserInitiated, completion: completion)
            }
            return
        }
        debugLog("completeHide() -> startDisappearingAnimation")
        transition.startDisappearingAnimation { [weak self] in
            self?.finalizeHide(isUserInitiated: isUserInitiated, completion: completion)
        }
    }
    
    private func finalizeHide(isUserInitiated: Bool, completion: ((Bool) -> Void)?) {
        debugLog("finalizeHide() -> didHideOffer")
        self.delegate?.presentationControllerDidHideOffer(isUserInitiated: isUserInitiated)
        debugLog("finalizeHide() -> schedule cleanup")
        scheduleCleanupAfterFrames(2) { [weak self] in
            guard let self = self else {
                completion?(false)
                return
            }
            self.debugLog("finalizeHide() -> remove contentView")
            self.contentView?.removeFromSuperview()
            self.contentView = nil
            self.debugLog("finalizeHide() -> hide window")
            self.inAppWindow.isHidden = true
            self.presentingAnimator = nil
            self.state = .idle
            completion?(true)
        }
    }

    private func scheduleCleanupAfterFrames(_ frames: Int, cleanup: @escaping () -> Void) {
        cleanupDisplayLink?.invalidate()
        pendingCleanupFrames = max(1, frames)
        pendingCleanup = cleanup
        let displayLink = CADisplayLink(target: self, selector: #selector(handleCleanupTick))
        displayLink.add(to: .main, forMode: .common)
        cleanupDisplayLink = displayLink
    }

    @objc private func handleCleanupTick() {
        pendingCleanupFrames -= 1
        if pendingCleanupFrames <= 0 {
            cleanupDisplayLink?.invalidate()
            cleanupDisplayLink = nil
            pendingCleanup?()
            pendingCleanup = nil
        }
    }

    private func debugLog(_ message: String) {
        guard Self.debugLogEnabled else { return }
        let timestamp = String(format: "%.4f", CACurrentMediaTime())
        print("🧭 [InAppPresentation \(timestamp)] \(message)")
    }
}

// MARK: - Private UIWindow + statusBarHeight

private extension UIWindow {
    
    var statusBarHeight: CGFloat {
        return (windowScene?.statusBarManager?.statusBarFrame.height).unwrapped(or: .zero)
    }
}

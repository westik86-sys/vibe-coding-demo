//
//  InAppTransition.swift
//  ProductAvatarPicker
//
//  Migrated from OffersKit
//  Created by t.begishev on 25.05.2022.
//

import UIKit

protocol InAppTransition: AnyObject {
    typealias Completion = () -> Void
    
    var animatableComponents: [UIView] { get set }
    
    func startAppearingAnimation(_ completion: @escaping Completion)
    func startDisappearingAnimation(_ completion: @escaping Completion)
    func performChanges(with translation: CGPoint, animated: Bool, completion: (() -> Void)?)
    func isHidingNeeded(with translation: CGPoint) -> Bool
    func isOpeningNeeded(with translation: CGPoint) -> Bool
}

extension InAppTransition {
    
    func performChanges(with translation: CGPoint, animated: Bool) {
        performChanges(with: translation, animated: animated, completion: nil)
    }
}

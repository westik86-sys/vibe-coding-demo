//
//  Optional+Unwrapped.swift
//  ProductAvatarPicker
//
//  Migrated from OffersKit
//

import Foundation

extension Optional {
    
    func unwrapped(or defaultValue: Wrapped) -> Wrapped {
        switch self {
        case let .some(wrapped):
            return wrapped
        case .none:
            return defaultValue
        }
    }
}

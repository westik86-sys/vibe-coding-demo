//
//  CashbackBadge.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 15.12.2025.
//

import SwiftUI

struct CashbackBadge: View, Hashable {
    var text: String?
    var size: Size
    var appearance: Appearance
    var iconOverride: UIImage? = nil
    
    var body: some View {
        HStack(spacing: 2) {
            icon?
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size.iconSize, height: size.iconSize)
            if let text {
                Text(text)
                    .font(size.font)
                    .foregroundStyle(appearance.foregroundColor)
                    .particleEffect(fontSize: size.fontSize)
            }
        }
        .foregroundStyle(appearance.foregroundColor)
        .padding(size.edgeInsets(hasText: text != nil, hasIcon: icon != nil))
        .background(appearance.background)
        .clipShape(Capsule())
    }
    
    private var icon: Image? {
        iconOverride.map(Image.init) ?? appearance.defaultIcon
    }
}

// MARK: - Presets

extension CashbackBadge {
    static let arrowRoundUp = CashbackBadge(text: nil, size: .small, appearance: .lightText, iconOverride: .arrowRoundUp)
    static let clockHands = CashbackBadge(text: nil, size: .small, appearance: .lightText, iconOverride: .clockHands)
    static let receipt = CashbackBadge(text: nil, size: .small, appearance: .lightText, iconOverride: .receipt)
    static let partCircle = CashbackBadge(text: nil, size: .small, appearance: .accent2, iconOverride: .partCircle)
}

// MARK: - Model

extension CashbackBadge {
    
    enum Size: Hashable {
        case small
        case medium
        
        var fontSize: CGFloat {
            switch self {
            case .small: 11
            case .medium: 13
            }
        }
        var font: Font {
            switch self {
            case .small: .system(size: fontSize, weight: .bold)
            case .medium: .system(size: fontSize, weight: .semibold)
            }
        }
        
        func edgeInsets(hasText: Bool = true, hasIcon: Bool = false) -> EdgeInsets {
            if hasText {
                switch self {
                case .small: EdgeInsets(top: 1.5, leading: hasIcon ? 3 : 4, bottom: 1.5, trailing: 4)
                case .medium: EdgeInsets(top: 1.5, leading: hasIcon ? 4 : 6, bottom: 2.5, trailing: 6)
                }
            } else {
                switch self {
                case .small: EdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 3)
                case .medium: EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
                }
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: 10.0
            case .medium: 12.0
            }
        }
    }
    
    enum Appearance: Hashable {
        case black
        case platinum
        case accent1
        case accent2
        case lightText
        
        var foregroundColor: Color {
            switch self {
            case .black: Color.Text.primaryOnDark
            case .platinum: Color.Text.primaryOnDark
            case .accent1: Color.Text.primaryOnAccent1
            case .accent2: Color.Text.primaryOnDark
            case .lightText: Color.Text.primaryOnDark
            }
        }
        
        @ViewBuilder
        var background: some View {
            switch self {
            case .black:
                LinearGradient(
                    colors: [Color.Brand.blackGradientStart,
                             Color.Brand.blackGradientEnd],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
            case .platinum:
                LinearGradient(
                    colors: [Color.Brand.platinumGradientStart,
                             Color.Brand.platinumGradientEnd],
                    startPoint: .bottomLeading,
                    endPoint: .bottomTrailing
                )
            case .accent1:
                Color.Background.accent1
            case .accent2:
                Color.Background.accent2
            case .lightText:
                Color.Background.neutral4
            }
        }
        
        var defaultIcon: Image? {
            switch self {
            case .black: Image(.black).renderingMode(.template)
            case .platinum: Image(.platinum).renderingMode(.template)
            case .accent1: nil
            case .accent2: nil
            case .lightText: nil
            }
        }
    }
}

// MARK: - Preview

#Preview(traits: .sizeThatFitsLayout) {
    VStack {
        HStack {
            CashbackBadge.arrowRoundUp
            CashbackBadge.clockHands
            CashbackBadge.receipt
            CashbackBadge.partCircle
        }
        Divider()
            .padding()
        HStack {
            CashbackBadge(text: "783 ₽", size: .medium, appearance: .black)
            CashbackBadge(text: "783 ₽", size: .medium, appearance: .platinum)
            CashbackBadge(text: "783 ₽", size: .medium, appearance: .accent1)
            CashbackBadge(text: "783 ₽", size: .medium, appearance: .lightText)
        }
        HStack {
            CashbackBadge(text: "783 ₽", size: .small, appearance: .black)
            CashbackBadge(text: "783 ₽", size: .small, appearance: .platinum)
            CashbackBadge(text: "783 ₽", size: .small, appearance: .accent1)
            CashbackBadge(text: "783 ₽", size: .small, appearance: .lightText)
        }
    }
    .padding()
}

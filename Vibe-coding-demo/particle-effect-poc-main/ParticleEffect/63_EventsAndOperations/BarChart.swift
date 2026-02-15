//
//  BarChart.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 12.01.2026.
//

import SwiftUI

struct BarChart: View {
    private var segments: [Segment]
    
    init(style: Style) {
        segments = zip(style.colors, style.fractions).map(Segment.init)
    }
    
    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: .zero) {
                ForEach(segments) { segment in
                    segment.color
                        .frame(width: proxy.size.width * segment.fraction)
                }
            }
        }
        .frame(height: 12)
        .clipShape(Capsule())
    }
}

// MARK: - Styles

extension BarChart {
    
    enum Style: CaseIterable {
        case spending
        case income
        case transactions
        
        fileprivate var colors: [Color] {
            let hexValues: [UInt64]
            switch self {
            case .spending:
                hexValues = [0xF99AD3, 0x9067E9, 0x4FC5DF, 0x1766FF, 0xFE788B, 0xB4CDDB]
            case .income:
                hexValues = [0x298389, 0x5BD1CA, 0x4FC5DF, 0x87E3CE, 0x9ED3DE]
            case .transactions:
                hexValues = [0x00BEE0, 0xFFDD2D, 0x9887F1, 0x1DACA4, 0x52BBE1]
            }
            return hexValues.map(Color.init(hex:))
        }
        
        fileprivate var fractions: [CGFloat] {
            switch self {
            case .spending:
                [0.28333, 0.21667, 0.20833, 0.14167, 0.1, 0.05]
            case .income:
                [0.47692, 0.20833, 0.21538, 0.06154, 0.03846]
            case .transactions:
                [0.31538, 0.2, 0.13846, 0.10769, 0.23846]
            }
        }
    }
    
    fileprivate struct Segment: Identifiable {
        let id = UUID()
        let color: Color
        let fraction: CGFloat
    }
}

extension Color {
    
    fileprivate init(hex: UInt64) {
        let r = Double((hex & 0xff0000) >> 16) / 255
        let g = Double((hex & 0x00ff00) >> 8) / 255
        let b = Double(hex & 0x0000ff) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        ForEach(BarChart.Style.allCases, id: \.self) {
            BarChart(style: $0)
        }
    }
    .padding(50)
}

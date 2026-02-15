
//
//  BubbleShape.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 04.12.2025.
//

import SwiftUI

struct BubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let arrowPath = Path { path in
            path.move(to: CGPoint(x: .zero, y: 0))
            path.addCurve(
                to: CGPoint(x: 11.73, y: 7.61),
                control1: CGPoint(x: 4.82, y: .zero),
                control2: CGPoint(x: 8.42, y: 4.68)
            )
            path.addCurve(
                to: CGPoint(x: 19.07, y: 4.36),
                control1: CGPoint(x: 14.52, y: 10.12),
                control2: CGPoint(x: 19.1, y: 8)
            )
            path.addCurve(
                to: CGPoint(x: 23.48, y: .zero),
                control1: CGPoint(x: 19.1, y: 1.94),
                control2: CGPoint(x: 21.06, y: .zero)
            )
            path.addLine(to: CGPoint(x: .zero, y: 0))
            path.closeSubpath()
        }
        
        let bubbleRect = CGRect(x: rect.origin.x, y: rect.origin.y,
                                width: rect.width, height: rect.height)
        var bubblePath = Path(roundedRect: bubbleRect, cornerRadius: 40)
        bubblePath.addPath(arrowPath, transform: CGAffineTransform(
            translationX: rect.origin.x + rect.width / 2 - 16,
            y: rect.height
        ))
        return bubblePath
    }
}

//
//  FocusAccountView.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 15.01.2026.
//

import SwiftUI

struct FocusAccountView: View {
    
    var body: some View {
        VStack(spacing: 60) {
            rainbowDigits
                .padding(.horizontal)
            metalDigits
                .padding(.horizontal, 60)
        }
        .padding(.vertical, 30)
    }
    
    private var rainbowDigits: some View {
        let hueColors = stride(from: 0, to: 1, by: 0.01).map {
            Color(hue: $0, saturation: 1, brightness: 1)
        }
        return Text("12 345 ₽")
            .font(.system(size: 70, weight: .bold, design: .rounded))
            .foregroundStyle(LinearGradient(
                colors: hueColors,
                startPoint: .leading,
                endPoint: .trailing
            ))
            .lineLimit(1)
            .particleEffect(fontSize: 70, respectBounds: false)
    }
    
    private var metalDigits: some View {
        GeometryReader { proxy in
            let image = UIImage.metalDigits
            let imageSize = image.size.aspectFitted(proxy.size)
            let fontSize = imageSize.height / 0.7
            
            Image(uiImage: image)
                .resizable()
                .frame(width: imageSize.width, height: imageSize.height)
                .particleEffect(fontSize: fontSize, respectBounds: false)
        }
    }
}

extension CGSize {
    
    fileprivate func aspectFitted(_ size: CGSize) -> CGSize {
        let scale = min(size.width / max(1.0, width), size.height / max(1.0, height))
        return CGSize(width: floor(width * scale), height: floor(height * scale))
    }
}

#Preview {
    FocusAccountView()
}

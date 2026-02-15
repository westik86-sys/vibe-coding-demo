//
//  CGImage+PixelColor.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 14.01.2026.
//

import CoreGraphics

public extension CGImage {
    
    func pixelColor(x: Int, y: Int) -> SIMD4<UInt8> {
        assert(
            0..<width ~= x && 0..<height ~= y,
            "Pixel coordinates are out of bounds")
        
        guard
            let data = dataProvider?.data,
            let dataPtr = CFDataGetBytePtr(data),
            let colorSpaceModel = colorSpace?.model,
            let componentLayout = bitmapInfo.componentLayout
        else {
            assertionFailure("Could not get a pixel of an image")
            return .zero
        }
        
        assert(
            colorSpaceModel == .rgb,
            "The only supported color space model is RGB")
        assert(
            bitsPerPixel == 32 || bitsPerPixel == 24,
            "A pixel is expected to be either 4 or 3 bytes in size")
        
        let bytesPerRow = bytesPerRow
        let bytesPerPixel = bitsPerPixel/8
        let pixelOffset = y*bytesPerRow + x*bytesPerPixel
        
        if componentLayout.count == 4 {
            let components = (
                dataPtr[pixelOffset + 0],
                dataPtr[pixelOffset + 1],
                dataPtr[pixelOffset + 2],
                dataPtr[pixelOffset + 3]
            )
            
            var alpha: UInt8 = 0
            var red: UInt8 = 0
            var green: UInt8 = 0
            var blue: UInt8 = 0
            
            switch componentLayout {
            case .bgra:
                alpha = components.3
                red = components.2
                green = components.1
                blue = components.0
            case .abgr:
                alpha = components.0
                red = components.3
                green = components.2
                blue = components.1
            case .argb:
                alpha = components.0
                red = components.1
                green = components.2
                blue = components.3
            case .rgba:
                alpha = components.3
                red = components.0
                green = components.1
                blue = components.2
            default:
                return .zero
            }
            
            // If chroma components are premultiplied by alpha and the alpha is `0`,
            // keep the chroma components to their current values.
            if bitmapInfo.chromaIsPremultipliedByAlpha && alpha != 0 {
                let invUnitAlpha = 255/CGFloat(alpha)
                red = UInt8(min((CGFloat(red)*invUnitAlpha).rounded(), CGFloat(UInt8.max)))
                green = UInt8(min((CGFloat(green)*invUnitAlpha).rounded(), CGFloat(UInt8.max)))
                blue = UInt8(min((CGFloat(blue)*invUnitAlpha).rounded(), CGFloat(UInt8.max)))
            }
            
            return [red, green, blue, alpha]
            
        } else if componentLayout.count == 3 {
            let components = (
                dataPtr[pixelOffset + 0],
                dataPtr[pixelOffset + 1],
                dataPtr[pixelOffset + 2]
            )
            
            var red: UInt8 = 0
            var green: UInt8 = 0
            var blue: UInt8 = 0
            
            switch componentLayout {
            case .bgr:
                red = components.2
                green = components.1
                blue = components.0
            case .rgb:
                red = components.0
                green = components.1
                blue = components.2
            default:
                return .zero
            }
            
            return [red, green, blue, 255]
            
        } else {
            assertionFailure("Unsupported number of pixel components")
            return .zero
        }
    }
    
}

public extension CGBitmapInfo {
    
    enum ComponentLayout {
        
        case bgra
        case abgr
        case argb
        case rgba
        case bgr
        case rgb
        
        var count: Int {
            switch self {
            case .bgr, .rgb: return 3
            default: return 4
            }
        }
        
    }
    
    var componentLayout: ComponentLayout? {
        guard let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue) else { return nil }
        let isLittleEndian = contains(.byteOrder32Little)
        
        if alphaInfo == .none {
            return isLittleEndian ? .bgr : .rgb
        }
        let alphaIsFirst = alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst
        
        if isLittleEndian {
            return alphaIsFirst ? .bgra : .abgr
        } else {
            return alphaIsFirst ? .argb : .rgba
        }
    }
    
    var chromaIsPremultipliedByAlpha: Bool {
        let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue)
        return alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
    }
}

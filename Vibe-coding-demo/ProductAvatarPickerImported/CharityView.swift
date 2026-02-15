import SwiftUI
import UIKit

struct CharityView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var path: NavigationPath
    @State private var donationValue: Int = 0
    @State private var displayProgress: Float = 0.0
    @State private var percentCenter: CGPoint = .zero
    @State private var hasPercentCenter = false
    @State private var lastPulseTick: Int = -1
    @State private var pulseBoost: Float = 0.0
    @State private var showTuningPanel = false
    @State private var showBottomSheet = false
    @State private var shaderSettings = CharityShaderSettings()
    @State private var showEdgeGlow = false
    @State private var breatheBoost: Float = 0.0
    @State private var shockStartDate: Date?
    @State private var shockBreatheBoost: Float = 0.0
    @State private var text1Opacity: Double = 1.0
    @State private var text2Opacity: Double = 0.0
    
    private let successHaptic = UINotificationFeedbackGenerator()
    private let shockDuration: TimeInterval = 0.75
    private let shockWidth: Float = 0.4025
    private let shockIntensity: Float = 0.55
    private let shockBreatheBoostValue: Float = 0.35
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : lightBackgroundTint.color
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.2, green: 0.2, blue: 0.2)
    }

    private typealias BackgroundTint = (color: Color, simd: SIMD3<Float>)

    private var lightBackgroundTint: BackgroundTint {
        tintedBackground(from: currentBaseColor, saturationMultiplier: 0.2)
    }

    private func tintedBackground(from rgb: SIMD3<Float>, saturationMultiplier: CGFloat) -> BackgroundTint {
        let uiColor = UIColor(
            red: CGFloat(rgb.x),
            green: CGFloat(rgb.y),
            blue: CGFloat(rgb.z),
            alpha: 1.0
        )
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let newSaturation = min(max(saturation * saturationMultiplier, 0.0), 1.0)
            let tint = UIColor(hue: hue, saturation: newSaturation, brightness: 1.0, alpha: 1.0)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            tint.getRed(&r, green: &g, blue: &b, alpha: &a)
            return (Color(tint), SIMD3<Float>(Float(r), Float(g), Float(b)))
        }
        return (Color.white, SIMD3<Float>(1.0, 1.0, 1.0))
    }
    
    // Dynamic color gradient based on donation value
    private var currentBaseColor: SIMD3<Float> {
        if colorScheme == .light && donationValue == 100 {
            // Light mode, 100%: only red/orange (no yellow)
            return SIMD3<Float>(1.0, 0.38, 0.0)
        }
        let progress = Float(donationValue) / 100.0
        
        if progress < 0.25 {
            // 0-25%: Bright Blue to Vibrant Purple
            let t = progress * 4.0 // 0.0 to 1.0
            let brightBlue = SIMD3<Float>(0.0, 0.6, 1.0) // Яркий синий
            let vibrantPurple = SIMD3<Float>(0.8, 0.2, 1.0) // Яркий фиолетовый
            return mix(brightBlue, vibrantPurple, t)
        } else if progress < 0.5 {
            // 25-50%: Vibrant Purple to Softer Magenta-Pink
            let t = (progress - 0.25) * 4.0 // 0.0 to 1.0
            let vibrantPurple = SIMD3<Float>(0.8, 0.2, 1.0) // Яркий фиолетовый
            let softerMagenta = SIMD3<Float>(0.95, 0.3, 0.57) // Чуть менее яркий маджента-розовый (95% вместо 100%)
            return mix(vibrantPurple, softerMagenta, t)
        } else {
            // 50-100%: Softer Magenta-Pink to Red
            let t = (progress - 0.5) * 2.0 // 0.0 to 1.0
            let softerMagenta = SIMD3<Float>(0.95, 0.3, 0.57) // Чуть менее яркий маджента-розовый
            let red = SIMD3<Float>(0.929, 0.204, 0.216) // #ED3437
            return mix(softerMagenta, red, t)
        }
    }
    
    private var currentGlowColor: SIMD3<Float> {
        if colorScheme == .light && donationValue == 100 {
            // Light mode, 100%: clean orange glow
            return SIMD3<Float>(1.0, 0.5, 0.0)
        }
        let progress = Float(donationValue) / 100.0
        
        if progress < 0.25 {
            // 0-25%: Bright Cyan to Softer Purple
            let t = progress * 4.0
            let brightCyan = SIMD3<Float>(0.2, 0.8, 1.0) // Яркий циан
            let softerPurple = SIMD3<Float>(0.75, 0.35, 0.85) // Менее яркий фиолетовый
            return mix(brightCyan, softerPurple, t)
        } else if progress < 0.5 {
            // 25-50%: Softer Purple to Softer Pink (снижена яркость для 23-40%)
            let t = (progress - 0.25) * 4.0
            let softerPurple = SIMD3<Float>(0.75, 0.35, 0.85) // Менее яркий фиолетовый
            let softerPink = SIMD3<Float>(0.85, 0.45, 0.62) // Еще менее яркий розовый
            return mix(softerPurple, softerPink, t)
        } else {
            // 50-100%: Softer Pink to Yellow
            let t = (progress - 0.5) * 2.0
            let softerPink = SIMD3<Float>(0.85, 0.45, 0.62)
            let yellow = SIMD3<Float>(1.0, 0.85, 0.0) // Яркий желтый
            return mix(softerPink, yellow, t)
        }
    }
    
    // Контрастный цвет для внешних краев эффекта
    private var currentEdgeColor: SIMD3<Float> {
        if colorScheme == .light && donationValue == 100 {
            // Light mode, 100%: deeper orange-red edges
            return SIMD3<Float>(1.0, 0.3, 0.0)
        }
        let progress = Float(donationValue) / 100.0
        
        if progress < 0.25 {
            // 0-25%: Deep Blue to Deep Purple (темнее основного)
            let t = progress * 4.0
            let deepBlue = SIMD3<Float>(0.0, 0.3, 0.7) // Глубокий синий
            let deepPurple = SIMD3<Float>(0.5, 0.1, 0.7) // Глубокий фиолетовый
            return mix(deepBlue, deepPurple, t)
        } else if progress < 0.5 {
            // 25-50%: Deep Purple to Deep Magenta
            let t = (progress - 0.25) * 4.0
            let deepPurple = SIMD3<Float>(0.5, 0.1, 0.7) // Глубокий фиолетовый
            let deepMagenta = SIMD3<Float>(0.7, 0.15, 0.4) // Глубокий маджента
            return mix(deepPurple, deepMagenta, t)
        } else {
            // 50-100%: Deep Magenta to Orange
            let t = (progress - 0.5) * 2.0
            let deepMagenta = SIMD3<Float>(0.7, 0.15, 0.4)
            let orange = SIMD3<Float>(1.0, 0.5, 0.0) // Оранжевый (контраст с желтым)
            return mix(deepMagenta, orange, t)
        }
    }
    
    private func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ t: Float) -> SIMD3<Float> {
        return a + (b - a) * t
    }
    
    private var edgeGlowOpacity: Double {
        guard showEdgeGlow else { return 0.0 }
        
        if donationValue < 90 {
            return 0.0
        } else if donationValue == 100 {
            return 0.15
        } else {
            // Плавный фейд от 90 до 100: 0.0 -> 0.15
            let progress = Double(donationValue - 90) / 10.0
            return progress * 0.15
        }
    }

    private func triggerShockWave() {
        successHaptic.prepare()
        successHaptic.notificationOccurred(.success)
        shockStartDate = Date()
        shockBreatheBoost = shockBreatheBoostValue
        withAnimation(.easeOut(duration: shockDuration)) {
            shockBreatheBoost = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showBottomSheet = true
            }
        }
    }
    
    var body: some View {
        ZStack {
            if #available(iOS 17.0, *) {
                CharityRippleBackground(
                    percentCenter: percentCenter,
                    hasPercentCenter: hasPercentCenter,
                    progress: displayProgress,
                    pulseBoost: pulseBoost,
                    breatheBoost: breatheBoost + shockBreatheBoost,
                    shockStartDate: shockStartDate,
                    shockDuration: Float(shockDuration),
                    shockWidth: shockWidth,
                    shockIntensity: shockIntensity,
                    settings: shaderSettings,
                    baseColor: currentBaseColor,
                    glowColor: currentGlowColor,
                    edgeColor: currentEdgeColor
                )
                .animation(.easeInOut(duration: 0.8), value: currentBaseColor)
                .animation(.easeInOut(duration: 0.8), value: currentGlowColor)
                .ignoresSafeArea()
            } else {
                backgroundColor
                    .ignoresSafeArea()
            }
            
            // Edge glow effect for values 90-100
            GeometryReader { geometry in
                ZStack {
                    // Top edge
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange.opacity(edgeGlowOpacity),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * 0.162)
                    .frame(maxHeight: .infinity, alignment: .top)
                    
                    // Bottom edge
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange.opacity(edgeGlowOpacity),
                            Color.clear
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: geometry.size.height * 0.162)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    
                    // Leading edge
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange.opacity(edgeGlowOpacity),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.162)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Trailing edge
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange.opacity(edgeGlowOpacity),
                            Color.clear
                        ]),
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                    .frame(width: geometry.size.width * 0.162)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.6), value: edgeGlowOpacity)
            
            VStack(spacing: 0) {
                Text("Какой процент от кэшбэка\nВы бы хотели пожертвовать?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                
                Spacer()
                
                Text("\(donationValue)%")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(primaryTextColor)
                    .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 0)
                    .shadow(color: .white.opacity(0.15), radius: 16, x: 0, y: 0)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: PercentCenterKey.self,
                                value: CGPoint(
                                    x: proxy.frame(in: .global).midX,
                                    y: proxy.frame(in: .global).midY
                                )
                            )
                        }
                    )
                    .onTapGesture {
                        triggerShockWave()
                    }
                
                Spacer()
                
                ZStack {
                    ZStack {
                        Text(donationValue == 0 ? "Важен каждый 🌟" : "Примерно \(approxRubles(for: donationValue)) ₽")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                            .opacity(text1Opacity)
                        
                        Text("Вот это щедрость!")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                            .opacity(text2Opacity)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6.5)
                    .padding(.bottom, 7.5)
                    .background(
                        colorScheme == .dark
                            ? Color.white.opacity(0.1)
                            : Color.white.opacity(0.25)
                    )
                    .clipShape(Capsule())
                }
                .padding(.bottom, 40)
                
                RulerPicker(
                    range: 0...100,
                    value: $donationValue
                )
                .frame(height: 50)
                .padding(.bottom, 52)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showTuningPanel.toggle()
                    }
                }) {
                    Text("Помочь")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(primaryTextColor)
                        .kerning(-0.41)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            colorScheme == .dark
                                ? Color.white.opacity(0.3)
                                : Color.black.opacity(0.08)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .overlay(alignment: .bottom) {
            if showTuningPanel {
                ShaderTuningPanel(settings: $shaderSettings, isPresented: $showTuningPanel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showBottomSheet) {
            BottomSheetView()
                .presentationDetents([.height(sheetDetentHeight)])
                .presentationDragIndicator(.hidden)
        }
        .onPreferenceChange(PercentCenterKey.self) { point in
            if let point {
                percentCenter = point
                hasPercentCenter = true
            }
        }
        .onChange(of: donationValue) { newValue in
            withAnimation(.easeInOut(duration: 0.6)) {
                // При значении < 10 прогресс минимальный (0.0-0.1)
                // При значении >= 10 прогресс нарастает от 0.1 до 1.0
                if newValue < 10 {
                    displayProgress = Float(newValue) / 100.0
                } else {
                    let normalizedValue = Float(newValue - 10) / 90.0 // 10-100 -> 0-1
                    displayProgress = 0.1 + normalizedValue * 0.9 // Диапазон 0.1-1.0
                }
            }
            
            // Edge glow and breathe boost logic: show for 200ms, fade out 400ms when reaching 90+
            if newValue >= 90 {
                // Start both animations simultaneously
                withAnimation(.easeOut(duration: 0.2)) {
                    showEdgeGlow = true
                    if newValue == 100 {
                        breatheBoost = 0.1
                        // Trigger success haptic at 100%
                        successHaptic.notificationOccurred(.success)
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showEdgeGlow = false
                        breatheBoost = 0.0
                    }
                }
            }
            
            // Generosity message at 100%
            if newValue == 100 {
                // Step 1: Fade out text 1 (0.6s) - starts immediately with breathe animation
                withAnimation(.easeIn(duration: 0.6)) {
                    text1Opacity = 0
                }
                
                // Step 2: After fade out + 50ms pause, fade in text 2
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + 0.05) {
                    withAnimation(.easeIn(duration: 0.6)) {
                        text2Opacity = 1
                    }
                    
                    // Step 3: After showing 2s + 50ms pause, fade out text 2
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + 2.0 + 0.05) {
                        withAnimation(.easeIn(duration: 0.6)) {
                            text2Opacity = 0
                        }
                        
                        // Step 4: After fade out + 50ms pause, fade in text 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + 0.05) {
                            withAnimation(.easeIn(duration: 0.6)) {
                                text1Opacity = 1
                            }
                        }
                    }
                }
            } else {
                // Reset if value changes from 100
                if text1Opacity != 1 || text2Opacity != 0 {
                    text1Opacity = 1
                    text2Opacity = 0
                }
            }
            
            let tick = (newValue / 5) * 5
            if tick != lastPulseTick {
                lastPulseTick = tick
                let added = shaderSettings.pulseStrength
                let maxBoost = shaderSettings.pulseStrength * 2.5
                pulseBoost = min(pulseBoost + added, maxBoost)
                withAnimation(.easeOut(duration: Double(shaderSettings.pulseDecay)).delay(Double(shaderSettings.pulseDelay))) {
                    pulseBoost = 0.0
                }
            }
        }
        .onAppear {
            if donationValue < 10 {
                displayProgress = Float(donationValue) / 100.0
            } else {
                let normalizedValue = Float(donationValue - 10) / 90.0
                displayProgress = 0.1 + normalizedValue * 0.9
            }
            
            // Prepare success haptic generator
            successHaptic.prepare()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("БФ «Котья лапка»")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                        .kerning(-0.24)
                    
                    Text("12 подписок")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .secondary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Версия 1") {
                        path.removeLast(path.count)
                        path.append(AppRoute.charityV1)
                    }
                    Button("Версия 2") {
                        path.removeLast(path.count)
                        path.append(AppRoute.charityV2)
                    }
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

@available(iOS 17.0, *)
private struct CharityRippleBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    let percentCenter: CGPoint
    let hasPercentCenter: Bool
    let progress: Float
    let pulseBoost: Float
    let breatheBoost: Float
    let shockStartDate: Date?
    let shockDuration: Float
    let shockWidth: Float
    let shockIntensity: Float
    let settings: CharityShaderSettings
    let baseColor: SIMD3<Float>
    let glowColor: SIMD3<Float>
    let edgeColor: SIMD3<Float>
    @State private var startDate = Date()

    private var shaderOvalColor: SIMD3<Float> {
        colorScheme == .dark ? settings.ovalColor : SIMD3<Float>(0.98, 0.98, 0.99)
    }

    private var lightBackgroundTint: SIMD3<Float> {
        tintedBackground(from: baseColor, saturationMultiplier: 0.2)
    }

    private var shaderBackgroundColor: SIMD3<Float> {
        colorScheme == .dark ? settings.backgroundColor : lightBackgroundTint
    }

    private var shaderNoiseStrength: Float {
        colorScheme == .dark ? settings.noiseStrength : settings.noiseStrength * 0.12
    }

    private func tintedBackground(from rgb: SIMD3<Float>, saturationMultiplier: CGFloat) -> SIMD3<Float> {
        let uiColor = UIColor(
            red: CGFloat(rgb.x),
            green: CGFloat(rgb.y),
            blue: CGFloat(rgb.z),
            alpha: 1.0
        )
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            let newSaturation = min(max(saturation * saturationMultiplier, 0.0), 1.0)
            let tint = UIColor(hue: hue, saturation: newSaturation, brightness: 1.0, alpha: 1.0)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            tint.getRed(&r, green: &g, blue: &b, alpha: &a)
            return SIMD3<Float>(Float(r), Float(g), Float(b))
        }
        return SIMD3<Float>(1.0, 1.0, 1.0)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { proxy in
                let time = Float(timeline.date.timeIntervalSince(startDate))
                let shaderSize = proxy.size
                let frame = proxy.frame(in: .global)
                let center: CGPoint = {
                    guard hasPercentCenter else { return CGPoint(x: 0.5, y: 0.5) }
                    let x = (percentCenter.x - frame.minX) / max(shaderSize.width, 1)
                    let y = (percentCenter.y - frame.minY) / max(shaderSize.height, 1)
                    return CGPoint(x: min(max(x, 0), 1), y: min(max(y, 0), 1))
                }()
                let shockElapsed: Float = {
                    guard let shockStartDate else { return -1.0 }
                    return Float(timeline.date.timeIntervalSince(shockStartDate))
                }()
                Rectangle()
                    .fill(Color.black)
                    .colorEffect(
                        ShaderLibrary.charityRipple(
                            .float2(shaderSize),
                            .float(time),
                            .float2(center.x, center.y),
                            .float4(progress, pulseBoost, settings.baseEnergy, settings.energyCurve),
                            .float4(settings.waveSpeed, settings.waveAmp, settings.brightnessBase, settings.climaxStart),
                            .float4(settings.glowSize, settings.glowIntensity, settings.climaxStrength, settings.pulseStrength),
                            .float4(settings.blurAmount, settings.coreWidth, settings.coreHeight, settings.coreRoundness),
                            .float4(shaderNoiseStrength, settings.noiseSize, 0.0, 0.0),
                            .float4(settings.rayIntensity, settings.rayCount, settings.raySpeed, settings.raySharpness),
                            .float3(baseColor.x, baseColor.y, baseColor.z),
                            .float3(glowColor.x, glowColor.y, glowColor.z),
                            .float3(edgeColor.x, edgeColor.y, edgeColor.z),
                            .float3(shaderOvalColor.x, shaderOvalColor.y, shaderOvalColor.z),
                            .float3(shaderBackgroundColor.x, shaderBackgroundColor.y, shaderBackgroundColor.z),
                            .float(breatheBoost),
                            .float(settings.distortion),
                            .float(settings.distortionAnimation),
                            .float4(shockElapsed, shockDuration, shockWidth, shockIntensity)
                        )
                    )
                    .frame(width: shaderSize.width, height: shaderSize.height)
                    .drawingGroup()
            }
        }
    }
}

private struct PercentCenterKey: PreferenceKey {
    static var defaultValue: CGPoint? = nil
    static func reduce(value: inout CGPoint?, nextValue: () -> CGPoint?) {
        if let next = nextValue() {
            value = next
        }
    }
}

private struct CharityShaderSettings: Codable {
    var baseEnergy: Float = 0.84  // 0.6 * 1.4 = 0.84 (увеличено на 40%)
    var energyCurve: Float = 1.0
    var climaxStart: Float = 0.92
    var climaxStrength: Float = 0.2
    var pulseStrength: Float = 0.08
    var pulseDecay: Float = 0.8
    var pulseDelay: Float = 0.08
    var waveSpeed: Float = 0.09
    var waveAmp: Float = 0.112  // 0.08 * 1.4 = 0.112 (увеличено на 40%)
    var brightnessBase: Float = 1.19  // 0.85 * 1.4 = 1.19 (увеличено на 40%)
    var glowSize: Float = 0.25
    var glowIntensity: Float = 0.77  // 0.55 * 1.4 = 0.77 (увеличено на 40%)
    var blurAmount: Float = 0.08
    var coreWidth: Float = 0.216
    var coreHeight: Float = 0.27
    var coreRoundness: Float = 2.1
    var noiseStrength: Float = 0.25
    var noiseSize: Float = 0.2
    var distortion: Float = 0.3  // Shape distortion (0.1-1.0)
    var distortionAnimation: Float = 0.5  // Animated distortion intensity (0.0-1.0)
    var rayIntensity: Float = 0.15
    var rayCount: Float = 10.0
    var raySpeed: Float = 0.12
    var raySharpness: Float = 4.2
    var baseColor: SIMD3<Float> = .init(0.0, 0.514, 1.0)
    var glowColor: SIMD3<Float> = .init(0.0, 0.6, 1.0)
    var ovalColor: SIMD3<Float> = .init(0.109, 0.109, 0.118)
    var backgroundColor: SIMD3<Float> = .init(0.109, 0.109, 0.118)

    private enum CodingKeys: String, CodingKey {
        case baseEnergy, energyCurve, climaxStart, climaxStrength
        case pulseStrength, pulseDecay, pulseDelay
        case waveSpeed, waveAmp, brightnessBase
        case glowSize, glowIntensity, blurAmount
        case coreWidth, coreHeight, coreRoundness
        case noiseStrength, noiseSize, distortion, distortionAnimation
        case rayIntensity, rayCount, raySpeed, raySharpness
        case baseColor, glowColor, ovalColor, backgroundColor
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseEnergy = try container.decode(Float.self, forKey: .baseEnergy)
        energyCurve = try container.decode(Float.self, forKey: .energyCurve)
        climaxStart = try container.decode(Float.self, forKey: .climaxStart)
        climaxStrength = try container.decode(Float.self, forKey: .climaxStrength)
        pulseStrength = try container.decode(Float.self, forKey: .pulseStrength)
        pulseDecay = try container.decode(Float.self, forKey: .pulseDecay)
        pulseDelay = try container.decode(Float.self, forKey: .pulseDelay)
        waveSpeed = try container.decode(Float.self, forKey: .waveSpeed)
        waveAmp = try container.decode(Float.self, forKey: .waveAmp)
        brightnessBase = try container.decode(Float.self, forKey: .brightnessBase)
        glowSize = try container.decode(Float.self, forKey: .glowSize)
        glowIntensity = try container.decode(Float.self, forKey: .glowIntensity)
        blurAmount = try container.decode(Float.self, forKey: .blurAmount)
        coreWidth = try container.decode(Float.self, forKey: .coreWidth)
        coreHeight = try container.decode(Float.self, forKey: .coreHeight)
        coreRoundness = try container.decode(Float.self, forKey: .coreRoundness)
        noiseStrength = try container.decode(Float.self, forKey: .noiseStrength)
        noiseSize = try container.decode(Float.self, forKey: .noiseSize)
        distortion = try container.decode(Float.self, forKey: .distortion)
        distortionAnimation = try container.decode(Float.self, forKey: .distortionAnimation)
        rayIntensity = try container.decodeIfPresent(Float.self, forKey: .rayIntensity) ?? rayIntensity
        rayCount = try container.decodeIfPresent(Float.self, forKey: .rayCount) ?? rayCount
        raySpeed = try container.decodeIfPresent(Float.self, forKey: .raySpeed) ?? raySpeed
        raySharpness = try container.decodeIfPresent(Float.self, forKey: .raySharpness) ?? raySharpness
        baseColor = Self.decodeColor(from: container, key: .baseColor)
        glowColor = Self.decodeColor(from: container, key: .glowColor)
        ovalColor = Self.decodeColor(from: container, key: .ovalColor)
        backgroundColor = Self.decodeColor(from: container, key: .backgroundColor)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(baseEnergy, forKey: .baseEnergy)
        try container.encode(energyCurve, forKey: .energyCurve)
        try container.encode(climaxStart, forKey: .climaxStart)
        try container.encode(climaxStrength, forKey: .climaxStrength)
        try container.encode(pulseStrength, forKey: .pulseStrength)
        try container.encode(pulseDecay, forKey: .pulseDecay)
        try container.encode(pulseDelay, forKey: .pulseDelay)
        try container.encode(waveSpeed, forKey: .waveSpeed)
        try container.encode(waveAmp, forKey: .waveAmp)
        try container.encode(brightnessBase, forKey: .brightnessBase)
        try container.encode(glowSize, forKey: .glowSize)
        try container.encode(glowIntensity, forKey: .glowIntensity)
        try container.encode(blurAmount, forKey: .blurAmount)
        try container.encode(coreWidth, forKey: .coreWidth)
        try container.encode(coreHeight, forKey: .coreHeight)
        try container.encode(coreRoundness, forKey: .coreRoundness)
        try container.encode(noiseStrength, forKey: .noiseStrength)
        try container.encode(noiseSize, forKey: .noiseSize)
        try container.encode(distortion, forKey: .distortion)
        try container.encode(distortionAnimation, forKey: .distortionAnimation)
        try container.encode(rayIntensity, forKey: .rayIntensity)
        try container.encode(rayCount, forKey: .rayCount)
        try container.encode(raySpeed, forKey: .raySpeed)
        try container.encode(raySharpness, forKey: .raySharpness)
        try Self.encodeColor(baseColor, into: &container, key: .baseColor)
        try Self.encodeColor(glowColor, into: &container, key: .glowColor)
        try Self.encodeColor(ovalColor, into: &container, key: .ovalColor)
        try Self.encodeColor(backgroundColor, into: &container, key: .backgroundColor)
    }

    private static func decodeColor(from container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> SIMD3<Float> {
        if let values = try? container.decode([Float].self, forKey: key), values.count == 3 {
            return SIMD3<Float>(values[0], values[1], values[2])
        }
        return SIMD3<Float>(0, 0, 0)
    }

    private static func encodeColor(_ color: SIMD3<Float>, into container: inout KeyedEncodingContainer<CodingKeys>, key: CodingKeys) throws {
        try container.encode([color.x, color.y, color.z], forKey: key)
    }
}

private struct ShaderPreset: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let settings: CharityShaderSettings
}

private struct ShaderTuningPanel: View {
    @Binding var settings: CharityShaderSettings
    @Binding var isPresented: Bool
    @State private var presets: [ShaderPreset] = []
    @State private var selectedPresetId: UUID?

    private let presetsKey = "charity_shader_presets"
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()

    var body: some View {
        GeometryReader { proxy in
            let maxHeight = proxy.size.height * 0.42 + 32
            VStack(spacing: 12) {
                HStack {
                    Text("Shader Tuning")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }

                ScrollView {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Button("Reset") {
                                settings = CharityShaderSettings()
                            }
                            .buttonStyle(TuningButtonStyle())

                            Button("Save") {
                                savePreset()
                            }
                            .buttonStyle(TuningButtonStyle(primary: true))

                            Button(action: { randomizeSettings() }) {
                                Image(systemName: "hexagon")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .buttonStyle(TuningButtonStyle())

                            Spacer()

                            if !presets.isEmpty {
                                Menu {
                                    ForEach(presets) { preset in
                                        Button(dateFormatter.string(from: preset.createdAt)) {
                                            settings = preset.settings
                                            selectedPresetId = preset.id
                                        }
                                    }
                                    Divider()
                                    Button(role: .destructive) {
                                        clearPresets()
                                    } label: {
                                        Text("Clear All")
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text("Load")
                                        Image(systemName: "chevron.down")
                                    }
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.bottom, 4)

                        SectionHeader("Animation")
                        SliderRow(title: "Base Energy", value: $settings.baseEnergy, range: 0.2...1.0)
                        SliderRow(title: "Energy Curve", value: $settings.energyCurve, range: 0.5...2.5)
                        SliderRow(title: "Climax Start", value: $settings.climaxStart, range: 0.8...0.99)
                        SliderRow(title: "Climax Strength", value: $settings.climaxStrength, range: 0.0...0.5)
                        SliderRow(title: "Pulse Strength", value: $settings.pulseStrength, range: 0.0...0.5)
                        SliderRow(title: "Pulse Decay", value: $settings.pulseDecay, range: 0.1...1.2)
                        SliderRow(title: "Pulse Delay", value: $settings.pulseDelay, range: 0.0...0.2)
                        SliderRow(title: "Wave Speed", value: $settings.waveSpeed, range: 0.02...0.12)
                        SliderRow(title: "Wave Amp", value: $settings.waveAmp, range: 0.02...0.3)
                        SliderRow(title: "Brightness Base", value: $settings.brightnessBase, range: 0.2...1.2)

                        SectionHeader("Glow")
                        SliderRow(title: "Glow Size", value: $settings.glowSize, range: 0.12...0.45)
                        SliderRow(title: "Glow Intensity", value: $settings.glowIntensity, range: 0.1...1.2)
                        SliderRow(title: "Blur Amount", value: $settings.blurAmount, range: 0.04...0.16)

                        SectionHeader("Core Shape")
                        SliderRow(title: "Core Width", value: $settings.coreWidth, range: 0.15...0.35)
                        SliderRow(title: "Core Height", value: $settings.coreHeight, range: 0.18...0.4)
                        SliderRow(title: "Core Roundness", value: $settings.coreRoundness, range: 1.5...3.0)

                        SectionHeader("Noise")
                        SliderRow(title: "Noise Strength", value: $settings.noiseStrength, range: 0.0...0.4)
                        SliderRow(title: "Noise Size", value: $settings.noiseSize, range: 0.05...0.6)
                        
                        SectionHeader("Distortion")
                        SliderRow(title: "Shape Distortion", value: $settings.distortion, range: 0.1...1.0)
                        SliderRow(title: "Animated Distortion", value: $settings.distortionAnimation, range: 0.0...1.0)

                        SectionHeader("Rays")
                        SliderRow(title: "Ray Intensity", value: $settings.rayIntensity, range: 0.0...0.6)
                        SliderRow(title: "Ray Count", value: $settings.rayCount, range: 6.0...40.0)
                        SliderRow(title: "Ray Speed", value: $settings.raySpeed, range: 0.0...0.6)
                        SliderRow(title: "Ray Sharpness", value: $settings.raySharpness, range: 1.0...6.0)

                        SectionHeader("Colors")
                        ColorSliders(title: "Base Color", color: $settings.baseColor)
                        ColorSliders(title: "Glow Color", color: $settings.glowColor)
                        ColorSliders(title: "Oval Color", color: $settings.ovalColor)
                        ColorSliders(title: "Background", color: $settings.backgroundColor)
                    }
                }
                .frame(maxHeight: maxHeight - 120)
            }
            .padding(16)
            .background(Color.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: maxHeight)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 0)
            .ignoresSafeArea(edges: .bottom)
            .onAppear {
                presets = loadPresets()
            }
        }
    }

    private func loadPresets() -> [ShaderPreset] {
        guard let data = UserDefaults.standard.data(forKey: presetsKey) else { return [] }
        return (try? JSONDecoder().decode([ShaderPreset].self, from: data)) ?? []
    }

    private func savePreset() {
        var current = loadPresets()
        current.insert(
            ShaderPreset(id: UUID(), createdAt: Date(), settings: settings),
            at: 0
        )
        if current.count > 10 {
            current = Array(current.prefix(10))
        }
        if let data = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(data, forKey: presetsKey)
            presets = current
        }
    }

    private func clearPresets() {
        UserDefaults.standard.removeObject(forKey: presetsKey)
        presets = []
    }

    private func randomizeSettings() {
        var next = settings
        next.baseEnergy = Float.random(in: 0.2...1.0)
        next.energyCurve = Float.random(in: 0.5...2.5)
        next.climaxStart = Float.random(in: 0.8...0.99)
        next.climaxStrength = Float.random(in: 0.0...0.5)
        next.pulseStrength = Float.random(in: 0.0...0.5)
        next.pulseDecay = Float.random(in: 0.1...1.2)
        next.pulseDelay = Float.random(in: 0.0...0.2)
        next.waveSpeed = Float.random(in: 0.02...0.12)
        next.waveAmp = Float.random(in: 0.02...0.3)
        next.brightnessBase = Float.random(in: 0.2...1.2)
        next.glowSize = Float.random(in: 0.12...0.45)
        next.glowIntensity = Float.random(in: 0.1...1.2)
        next.blurAmount = Float.random(in: 0.04...0.16)
        next.coreWidth = Float.random(in: 0.15...0.35)
        next.coreHeight = Float.random(in: 0.18...0.4)
        next.coreRoundness = Float.random(in: 1.5...3.0)
        next.noiseStrength = Float.random(in: 0.0...0.4)
        next.noiseSize = Float.random(in: 0.05...0.6)
        next.rayIntensity = Float.random(in: 0.0...0.6)
        next.rayCount = Float.random(in: 6.0...40.0)
        next.raySpeed = Float.random(in: 0.0...0.6)
        next.raySharpness = Float.random(in: 1.0...6.0)
        next.baseColor = SIMD3<Float>(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1))
        next.glowColor = SIMD3<Float>(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1))
        next.ovalColor = SIMD3<Float>(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1))
        next.backgroundColor = SIMD3<Float>(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1))

        withAnimation(.easeInOut(duration: 0.35)) {
            settings = next
        }
        print("Shader Randomize applied")
    }
}

private struct TuningButtonStyle: ButtonStyle {
    var primary = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(primary ? .black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(primary ? Color.white : Color.white.opacity(0.12))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Float($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound)
            )
            .tint(.white)
        }
        .padding(.vertical, 4)
    }
}

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
    }
}

private struct ColorSliders: View {
    let title: String
    @Binding var color: SIMD3<Float>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(red: Double(color.x), green: Double(color.y), blue: Double(color.z)))
                    .frame(width: 28, height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            SliderRow(title: "R", value: componentBinding(\.x), range: 0.0...1.0)
            SliderRow(title: "G", value: componentBinding(\.y), range: 0.0...1.0)
            SliderRow(title: "B", value: componentBinding(\.z), range: 0.0...1.0)
        }
        .padding(.vertical, 4)
    }

    private func componentBinding(_ keyPath: WritableKeyPath<SIMD3<Float>, Float>) -> Binding<Float> {
        Binding(
            get: { color[keyPath: keyPath] },
            set: { color[keyPath: keyPath] = $0 }
        )
    }
}

private enum DonationUnit {
    case percent
    case rubles
    
    var menuTitle: String {
        switch self {
        case .percent:
            return "Проценты"
        case .rubles:
            return "Рубли"
        }
    }
    
}

private func approxRubles(for percent: Int) -> Int {
    max(0, percent) * 30
}

private struct RulerPicker: View {
    let range: ClosedRange<Int>
    @Binding var value: Int
    @Environment(\.colorScheme) private var colorScheme
    
    private let tickWidth: CGFloat = 2
    private let tickSpacing: CGFloat = 10
    private let shortHeight: CGFloat = 25
    private let longHeight: CGFloat = 34
    private let indicatorHeight: CGFloat = 50
    private let indicatorColor = Color(red: 0.3373, green: 0.5569, blue: 0.9961)
    private let tickBaseColor = Color(red: 0.5725, green: 0.6, blue: 0.6353)
    private var trailStartColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.4275, green: 0.451, blue: 0.4863)
    }
    
    @State private var dragStartValue: Int?
    @State private var lastHapticValue: Int?
    @State private var lastDisplayValue: Int?
    @State private var trails: [TickTrail] = []
    private let haptic = UISelectionFeedbackGenerator()
    private let tickStep = 5
    private let longTickStep = 50
    private let trailDuration: TimeInterval = 0.25
    @State private var didPrepareHaptics = false
    
    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { proxy in
                let step = tickWidth + tickSpacing
                let centerX = proxy.size.width / 2
                let unitStep = step / CGFloat(tickStep)
                let unitSpacing = unitStep - tickWidth
                let displayValue = closestTickValue(for: value)
                let now = timeline.date
                
                ZStack {
                    HStack(spacing: unitSpacing) {
                        ForEach(Array(range), id: \.self) { item in
                            let isTick = isTickValue(item)
                            let isActive = isTick && (item == displayValue)
                            let trail = trailForTick(item, now: now, center: displayValue)
                            
                            ZStack {
                                Capsule(style: .continuous)
                                    .fill(isTick ? tickBaseColor.opacity(tickOpacity(for: item, center: displayValue)) : Color.clear)
                                    .frame(width: tickWidth, height: tickHeight(for: item))
                                
                                if let trail {
                                    Capsule(style: .continuous)
                                        .fill(trail.color)
                                        .frame(width: trail.width, height: trail.height)
                                }
                                
                                if isActive {
                                    Capsule(style: .continuous)
                                        .fill(indicatorColor)
                                        .frame(width: 2.5, height: indicatorHeight)
                                }
                            }
                            .frame(width: tickWidth, height: indicatorHeight)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(x: centerX - tickCenterX(for: displayValue, unitStep: unitStep, centerOffset: tickWidth / 2))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if dragStartValue == nil {
                                dragStartValue = value
                                haptic.prepare()
                            }
                            let delta = Int(round(-gesture.translation.width / unitStep))
                            let base = dragStartValue ?? value
                            let nextValue = clamp(base + delta)
                            if nextValue != value {
                                value = nextValue
                            }
                        }
                        .onEnded { _ in
                            dragStartValue = nil
                            lastHapticValue = nil
                        }
                )
            }
        }
        .onAppear {
            if !didPrepareHaptics {
                haptic.prepare()
                didPrepareHaptics = true
            }
        }
        .onChange(of: value) { newValue in
            let newDisplay = closestTickValue(for: newValue)
            let oldDisplay = lastDisplayValue ?? newDisplay
            if newDisplay != oldDisplay {
                let crossed = crossedTicks(from: oldDisplay, to: newDisplay)
                let now = Date()
                trails.append(contentsOf: crossed.map { TickTrail(value: $0, createdAt: now) })
                var hapticTicks = crossed
                hapticTicks.append(newDisplay)
                for tick in hapticTicks where isTickValue(tick) && tick != lastHapticValue {
                    haptic.selectionChanged()
                    lastHapticValue = tick
                }
            }
            lastDisplayValue = newDisplay
            pruneTrails()
        }
    }
    
    private func tickHeight(for value: Int) -> CGFloat {
        value % longTickStep == 0 ? longHeight : shortHeight
    }
    
    private func tickCenterX(for value: Int, unitStep: CGFloat, centerOffset: CGFloat) -> CGFloat {
        let clamped = clamp(value)
        let offsetUnits = CGFloat(clamped - range.lowerBound)
        return offsetUnits * unitStep + centerOffset
    }
    
    private func clamp(_ value: Int) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
    
    private func isTickValue(_ value: Int) -> Bool {
        value % tickStep == 0
    }
    
    private func closestTickValue(for value: Int) -> Int {
        let clamped = clamp(value)
        let snapped = Int(round(Double(clamped) / Double(tickStep))) * tickStep
        return min(max(snapped, range.lowerBound), range.upperBound)
    }
    
    private func tickOpacity(for item: Int, center: Int) -> Double {
        let distanceTicks = abs(item - center) / tickStep
        if distanceTicks <= 1 {
            return 1.0
        }
        let fadeSteps = Double(distanceTicks - 1)
        return max(0, 1.0 - (fadeSteps * 0.1))
    }
    
    private func crossedTicks(from oldValue: Int, to newValue: Int) -> [Int] {
        guard oldValue != newValue else { return [] }
        let step = oldValue < newValue ? tickStep : -tickStep
        var values: [Int] = []
        var current = oldValue
        while current != newValue {
            values.append(current)
            current += step
        }
        return values
    }
    
    private func pruneTrails() {
        let now = Date()
        trails.removeAll { now.timeIntervalSince($0.createdAt) > trailDuration }
    }
    
    private func trailForTick(_ value: Int, now: Date, center: Int) -> TrailVisual? {
        guard let trail = trails.last(where: { $0.value == value }) else {
            return nil
        }
        let progress = min(max(now.timeIntervalSince(trail.createdAt) / trailDuration, 0), 1)
        let height = lerp(indicatorHeight, tickHeight(for: value), progress)
        let width = lerp(2.5, tickWidth, progress)
        let color = lerpColor(
            from: trailStartColor,
            to: tickBaseColor,
            progress: progress,
            alphaMultiplier: tickOpacity(for: value, center: center)
        )
        return TrailVisual(width: width, height: height, color: color)
    }
    
    private func lerp(_ from: CGFloat, _ to: CGFloat, _ t: Double) -> CGFloat {
        from + (to - from) * CGFloat(t)
    }
    
    private func lerpColor(from: Color, to: Color, progress: Double, alphaMultiplier: Double) -> Color {
        let fromUIColor = UIColor(from)
        let toUIColor = UIColor(to)
        var fr: CGFloat = 0
        var fg: CGFloat = 0
        var fb: CGFloat = 0
        var fa: CGFloat = 0
        var tr: CGFloat = 0
        var tg: CGFloat = 0
        var tb: CGFloat = 0
        var ta: CGFloat = 0
        fromUIColor.getRed(&fr, green: &fg, blue: &fb, alpha: &fa)
        toUIColor.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        let r = fr + (tr - fr) * CGFloat(progress)
        let g = fg + (tg - fg) * CGFloat(progress)
        let b = fb + (tb - fb) * CGFloat(progress)
        let a = (fa + (ta - fa) * CGFloat(progress)) * CGFloat(alphaMultiplier)
        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
}

private struct TickTrail: Identifiable {
    let id = UUID()
    let value: Int
    let createdAt: Date
}

private struct TrailVisual {
    let width: CGFloat
    let height: CGFloat
    let color: Color
}

private enum SystemGlassStyle {
    static let fillColor = Color.white
    static let strokeColor = Color(uiColor: .separator).opacity(0.4)
    static let shadowColor = Color.black.opacity(0.1)
    static let shadowRadius: CGFloat = 10
    static let shadowOffset: CGFloat = 6
}

private struct SystemGlassBackground<S: Shape>: View {
    let shape: S
    let colorScheme: ColorScheme
    
    var body: some View {
        shape
            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : SystemGlassStyle.fillColor)
            .overlay(
                shape.stroke(
                    colorScheme == .dark ? Color.white.opacity(0.15) : SystemGlassStyle.strokeColor,
                    lineWidth: 0.5
                )
            )
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.6) : SystemGlassStyle.shadowColor,
                radius: SystemGlassStyle.shadowRadius,
                x: 0,
                y: SystemGlassStyle.shadowOffset
            )
    }
}

struct CharityViewV2: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var path: NavigationPath
    @State private var unit: DonationUnit = .percent
    @State private var donationValue: Int = 0
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.2, green: 0.2, blue: 0.2)
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("Какой процент от кэшбэка\nВы бы хотели пожертвовать?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.top, 62)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(donationValue)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(primaryTextColor)
                    
                    Menu {
                        Picker("Единицы", selection: $unit) {
                            Text("Проценты").tag(DonationUnit.percent)
                            Text("Рубли").tag(DonationUnit.rubles)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(unit.menuTitle)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(primaryTextColor)
                    }
                }
                
                Spacer()
                
                Text("Важен каждый 🌟")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 12)
                    .padding(.top, 6.5)
                    .padding(.bottom, 7.5)
                    .background(
                        (colorScheme == .dark
                            ? Color.white.opacity(0.1)
                            : Color(red: 0.0, green: 0.0627, blue: 0.1412).opacity(0.03))
                    )
                    .clipShape(Capsule())
                    .padding(.bottom, 40)
                
                RulerPicker(
                    range: 0...100,
                    value: $donationValue
                )
                .frame(height: 50)
                .padding(.bottom, 52)
                
                Button(action: {}) {
                    Text("Помочь")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(primaryTextColor)
                        .kerning(-0.41)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            colorScheme == .dark
                                ? Color.white.opacity(0.3)
                                : Color.black.opacity(0.08)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    ZStack {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
                    }
                    .frame(width: 24, height: 24)
                    .background(SystemGlassBackground(shape: Circle(), colorScheme: colorScheme))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Фонд котиков")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            .kerning(-0.24)
                        
                        Text("12 подписок")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .secondary)
                    }
                }
                .padding(.leading, 10)
                .padding(.trailing, 17)
                .padding(.top, 6)
                .padding(.bottom, 7)
                .frame(height: 44)
                .background(SystemGlassBackground(shape: Capsule(), colorScheme: colorScheme))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Версия 1") {
                        path.removeLast(path.count)
                        path.append(AppRoute.charityV1)
                    }
                    Button("Версия 2") {
                        path.removeLast(path.count)
                        path.append(AppRoute.charityV2)
                    }
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

private extension CharityView {
    var sheetDetentHeight: CGFloat {
        let topGap: CGFloat = topSafeAreaInset + 12
        return max(0, UIScreen.main.bounds.height - topGap)
    }

    var topSafeAreaInset: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            return 0
        }
        return windowScene.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.top ?? 0
    }
}

private struct BottomSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Color.white
                .ignoresSafeArea()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if #available(iOS 26.0, *) {
                            Button(role: .close) {
                                dismiss()
                            }
                        } else {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                }
        }
    }
}

#if DEBUG
private struct CharityPreviewHost: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            CharityView(path: $path)
        }
    }
}

#Preview {
    CharityPreviewHost()
}
#endif

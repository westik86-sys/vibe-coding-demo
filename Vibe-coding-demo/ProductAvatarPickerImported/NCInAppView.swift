//
//  NCInAppView.swift
//  ProductAvatarPicker
//
//  ЦУ + InApp - Центр уведомлений с InApp сообщениями
//

import SwiftUI

struct NCInAppView: View {
    @StateObject private var viewModel = NCInAppViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Черная полоска (gap) тоже активирует свайп открытия ЦУ
    private let swipeGapHeight: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            
            ZStack(alignment: .top) {
                // Черный фон
                Color.black
                    .ignoresSafeArea()
                
                // Черная полоска под островом — в зоне свайпа (не влияет на layout/фрейм острова)
                Color.clear
                    .frame(height: swipeGapHeight)
                    .position(
                        x: geometry.size.width / 2,
                        y: viewModel.islandHeight(screenHeight: screenHeight) + (swipeGapHeight / 2)
                    )
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                guard !viewModel.isExpanded else { return }
                                viewModel.handleDrag(
                                    translation: value.translation.height,
                                    screenHeight: screenHeight
                                )
                            }
                            .onEnded { value in
                                guard !viewModel.isExpanded else { return }
                                viewModel.handleDragEnd(
                                    translation: value.translation.height,
                                    velocity: value.predictedEndTranslation.height,
                                    screenHeight: screenHeight
                                )
                            }
                    )
                    .allowsHitTesting(!viewModel.isExpanded)
                
                // Остров - привязан к top
                islandView(screenHeight: screenHeight)
                    .frame(height: viewModel.islandHeight(screenHeight: screenHeight))
                    .position(
                        x: geometry.size.width / 2,
                        y: viewModel.islandHeight(screenHeight: screenHeight) / 2
                    )
                    .opacity(viewModel.isInAppShown && !viewModel.isIslandSnapActive ? 0 : 1)
                
                // Главная - позиция зависит от высоты острова
                contentView(screenHeight: screenHeight)
                    .frame(height: viewModel.contentHeight(screenHeight: screenHeight))
                    .position(
                        x: geometry.size.width / 2,
                        y: viewModel.contentY(screenHeight: screenHeight) + viewModel.contentHeight(screenHeight: screenHeight) / 2
                    )
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onPreferenceChange(IslandFramePreferenceKey.self) { frame in
            viewModel.updateIslandFrame(frame)
        }
        .onDisappear {
            // Скрываем InApp при уходе с экрана
            viewModel.hideInApp()
        }
    }
    
    // MARK: - Island (Остров)
    
    private func islandView(screenHeight: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            // Белый фон со скруглениями
            RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(islandBackgroundColor)
            
            // Контент - оба текста одновременно с разной прозрачностью
            ZStack(alignment: .bottom) {
                // Текст "Все уведомления" - исчезает быстро
                VStack(spacing: 0) {
                    Spacer()
                    Text("Все уведомления")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(primaryTextColor)
                        .kerning(-0.24)
                        .padding(.bottom, 18)
                }
                .opacity(viewModel.collapsedTextOpacity(screenHeight: screenHeight))
                
                // Текст "Остров" - появляется в конце
                VStack(spacing: 0) {
                    Spacer()
                    Button(action: {
                        viewModel.toggleExpanded()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Закрыть")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(closeButtonBackgroundColor)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScalePressButtonStyle())
                    .padding(.bottom, 32)
                }
                .opacity(viewModel.expandedTextOpacity(screenHeight: screenHeight))
            }
            
            // Кнопки - overlay поверх
            VStack {
                HStack {
                    // Кнопка InApp слева
                    Button(action: {
                        viewModel.toggleInApp()
                    }) {
                        Image(systemName: viewModel.isInAppShown ? "bell.slash.fill" : "bell.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(iconColor)
                            .frame(width: 28, height: 28)
                            .background(iconBackgroundColor)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Кнопка закрытия справа
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(iconColor)
                            .frame(width: 28, height: 28)
                            .background(iconBackgroundColor)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60) // Под статус бар
                
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: IslandFramePreferenceKey.self,
                    value: proxy.frame(in: .global)
                )
            }
        )
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    guard !viewModel.isExpanded else { return }
                    viewModel.handleDrag(
                        translation: value.translation.height,
                        screenHeight: screenHeight
                    )
                }
                .onEnded { value in
                    guard !viewModel.isExpanded else { return }
                    viewModel.handleDragEnd(
                        translation: value.translation.height,
                        velocity: value.predictedEndTranslation.height,
                        screenHeight: screenHeight
                    )
                }
        )
        .onTapGesture {
            guard !viewModel.isExpanded else { return }
            viewModel.toggleExpanded()
        }
    }
    
    // MARK: - Content View (Главная)
    
    private func contentView(screenHeight: CGFloat) -> some View {
        ZStack {
            // Белый фон со скруглениями
            UnevenRoundedRectangle(
                topLeadingRadius: 32,
                topTrailingRadius: 32
            )
            .fill(contentBackgroundStyle)
            
            // Контент
            Text("Главная")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(primaryTextColor)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.isExpanded {
                viewModel.toggleExpanded()
            }
        }
    }
    
    
}

private extension NCInAppView {
    var contentBackgroundStyle: AnyShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(hex: "1C1C1E"),
                        Color(hex: "1C1C1E").opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        
        return AnyShapeStyle(Color.white)
    }
    
    var islandBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : .white
    }
    
    
    var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "333333")
    }
    
    var iconColor: Color {
        colorScheme == .dark ? .white : Color(hex: "333333").opacity(0.6)
    }
    
    var iconBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1)
    }
    
    var closeButtonBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)
    }
}

private struct ScalePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct IslandFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NCInAppView()
    }
}

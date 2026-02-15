//
//  HomeView.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 15.12.2025.
//

import SwiftUI

struct HomeView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            notifications
            
            ScrollView(.vertical, content: mainContent)
                .background(Color.Background.base)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 32,
                    topTrailingRadius: 32
                ))
                .ignoresSafeArea()
        }
        .foregroundStyle(Color.Text.primary)
        .background(Color.black.ignoresSafeArea())
    }
    
    // MARK: - Notification Center
    
    private var notifications: some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(
                bottomLeadingRadius: 32,
                bottomTrailingRadius: 32
            )
            .foregroundStyle(Color.Background.base)
            .ignoresSafeArea()
            .layoutPriority(-1)
            
            HStack(spacing: 6) {
                Image(.bellFilled)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("Все уведомления")
                    .font(.system(size: 15))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 18)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Main Content
    
    private func mainContent() -> some View {
        VStack(spacing: .zero) {
            header
                .padding(.top, 16)
                .padding(.horizontal, 16)
            focusView
                .padding(.top, 68)
            operationsAndCashback
                .padding(.top, 12)
            accounts
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var header: some View {
        HStack(spacing: 8) {
            Image(.avatar)
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .padding(3)
                .background(Circle().strokeBorder(
                    Color.Brand.premium,
                    lineWidth: 1.5
                ))
                .frame(width: 40, height: 40)
            
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .padding(4)
                Text("Поиск")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(Color.Text.secondary)
            .padding(8)
            .background(Color.Background.neutral1)
            .clipShape(Capsule())
            
            // TODO: Update Colors
            Image(.gift)
                .resizable()
                .scaledToFit()
                .padding(10)
                .background(Color.purple.opacity(0.12))
                .clipShape(Circle())
                .frame(width: 40, height: 40)
        }
    }
    
    // MARK: - Focus View
    
    private var focusView: some View {
        VStack(spacing: .zero) {
            CashbackBadge(text: "783 ₽", size: .medium, appearance: .black)
            balance
                .padding(.top, 8)
            ZStack(alignment: .top) {
                Image(.cardsStack)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: 10)
                    .mask(alignment: .top) {
                        Spacer().frame(height: 64)
                        Color.black
                    }
                Image(.cardsStack)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .mask(alignment: .top) {
                        Color.black.frame(height: 64)
                    }
                actionPanel
                    .padding(.top, 64)
            }
            .padding(.top, 52)
        }
    }
    
    private var balance: some View {
        let isDark = colorScheme == .dark
        return Text("12 424 ₽")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(white: isDark ? 1.0 : 0.2, opacity: 1.0),
                                  location: 0.22),
                    Gradient.Stop(color: Color(white: isDark ? 1.0 : 0.2, opacity: 0.8),
                                  location: 0.71),
                ],
                startPoint: .bottom,
                endPoint: .top
            ))
            .particleEffect(fontSize: 48, respectBounds: false)
    }
    
    private var actionPanel: some View {
        let isDark: Bool = colorScheme == .dark
        let gradientBaseColor: Color = isDark ? .black : .white
        
        return HStack(spacing: .zero) {
            Spacer()
            actionButton(icon: Image(.plus), label: "Пополнить")
            actionButton(icon: Image(.qrScan), label: "Сканировать")
            actionButton(icon: Image(.arrowRight), label: "Перевести")
            actionButton(icon: nil, label: "Добавить")
            Spacer()
        }
        .background(LinearGradient(
            colors: [gradientBaseColor, gradientBaseColor.opacity(isDark ? 0.1 : 0.2)],
            startPoint: UnitPoint(x: 0.019, y: 0.5),
            endPoint: UnitPoint(x: 0.128, y: 0.5)
        ))
        .background(LinearGradient(
            colors: [gradientBaseColor, gradientBaseColor.opacity(isDark ? 0.1 : 0.2)],
            startPoint: UnitPoint(x: 0.981, y: 0.5),
            endPoint: UnitPoint(x: 0.872, y: 0.5)
        ))
        .background(LinearGradient(
            colors: [gradientBaseColor, gradientBaseColor.opacity(0.6)],
            startPoint: UnitPoint(x: 0.5, y: 0.6),
            endPoint: UnitPoint(x: 0.5, y: 0)
        ))
        .overlay(alignment: .top) {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(white: isDark ? 1.0 : 0.2, opacity: 0.0), location: 0.0),
                    Gradient.Stop(color: Color(white: isDark ? 1.0 : 0.2, opacity: isDark ? 0.15 : 0.1), location: 0.2),
                    Gradient.Stop(color: Color(white: isDark ? 1.0 : 0.2, opacity: isDark ? 0.15 : 0.1), location: 0.8),
                    Gradient.Stop(color: Color(white: isDark ? 1.0 : 0.2, opacity: 0.0), location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            .padding(.horizontal, 20)
        }
    }
    
    private func actionButton(icon: Image? = nil, label: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                if let icon {
                    icon
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .padding(14)
                        .background(Color.Background.elevation1)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 20, y: 5)
                        .padding(.horizontal, 15)
                } else {
                    Circle()
                        .fill(Color.Background.neutral1)
                        .strokeBorder(Color.Border.normal,
                                      style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .frame(width: 56, height: 56)
                        .padding(.horizontal, 15)
                }
                Text(label)
                    .lineLimit(1)
                    .font(.system(size: 13))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(icon == nil ? Color.Text.secondary : Color.Text.primary)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
    
    // MARK: - Operations & Cashback
    
    private var operationsAndCashback: some View {
        HStack(spacing: 19) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Все операции")
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Трат в феврале")
                        .font(.system(size: 15))
                    Text("49 765 ₽")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.Text.primary)
                        .particleEffect(fontSize: 15)
                }
                BarChart(style: .transactions)
                    .padding(.top, 12)
            }
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 20, trailing: 12))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.Background.elevation1)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.1), radius: 20, y: 5)
            
            VStack(alignment: .leading) {
                Text("Кэшбэк\nи бонусы")
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(2)
                Spacer()
                Image(.cashback)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 36)
            }
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 20, trailing: 14))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.Background.elevation1)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.1), radius: 20, y: 5)
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(Color.Text.primary)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Accounts
    
    private var accounts: some View {
        VStack(spacing: 20) {
            account(title: "65 000 ₽", description: "Платинум") {
                CashbackBadge(text: "234", size: .small, appearance: .platinum)
            }
            account(title: "65 000 ₽", description: "Совместный") {
                CashbackBadge(text: "183 ₽", size: .small, appearance: .black)
            }
            account(title: "65 000 ₽", description: "Сбер")
            account(title: "65 000 ₽", description: "Платинум") {
                CashbackBadge(text: "234", size: .small, appearance: .platinum)
            }
            account(title: "65 000 ₽", description: "Совместный") {
                CashbackBadge(text: "183 ₽", size: .small, appearance: .black)
            }
            account(title: "65 000 ₽", description: "Сбер")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    private func account<Badge: View>(title: String,
                                      description: String,
                                      badge: () -> Badge = EmptyView.init) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(.currencyRub)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .padding(8)
                .foregroundStyle(Color.white)
                .background(Color.Background.accent2)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.Text.primary)
                        .particleEffect(fontSize: 17)
                    Spacer()
                    badge()
                }
                Text(description)
                    .font(.system(size: 15))
                Image(.tuiThumbnailCard)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 32)
                    .padding(.top, 8)
            }
            .foregroundStyle(Color.Text.primary)
        }
        .padding(20)
        .background(Color.Background.elevation1)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 34, y: 6)
    }
}

#Preview {
    HomeView()
}

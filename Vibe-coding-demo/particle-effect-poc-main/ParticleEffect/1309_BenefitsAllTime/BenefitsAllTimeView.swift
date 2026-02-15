//
//  BenefitsAllTimeView.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 04.12.2025.
//

import SwiftUI

struct BenefitsAllTimeView: View {
    
    var body: some View {
        VStack(spacing: 40) {
            benefitSection
            buttonSection
            Spacer()
            bottomSection
        }
        .padding(.horizontal, 24)
        .foregroundStyle(Color.Text.primary)
        .background(
            ZStack(alignment: .top) {
                Color.Background.elevation1
                LinearGradient(
                    colors: [.allTimeGradientStart, .clear],
                    startPoint: .top, endPoint: .bottom
                ).frame(height: 320)
            }.ignoresSafeArea()
        )
    }
    
    // MARK: - Benefits
    
    private var benefitSection: some View {
        VStack(spacing: 0) {
            Text("Считаем c 2020 года")
                .font(.system(size: 15))
                .padding(EdgeInsets(top: 6, leading: 54, bottom: 8, trailing: 12))
                .background(BubbleShape().fill(Color.allTimeBubble))
                .overlay(alignment: .bottomLeading) {
                    Image(.benefitsBadge)
                        .resizable()
                        .frame(width: 44, height: 39)
                        .padding(.leading, 8)
                }
                .padding(.top, 15)
            Text("8  627  ₽")
                .font(.system(size: 76, weight: .bold, design: .rounded))
                .foregroundStyle(Color.Text.primary)
                .particleEffect(fontSize: 76, respectBounds: false)
                .padding(.top, 9)
            Text("Выгода растет, когда вы пользуетесь\nпродуктами и сервисами Т-Банка")
                .font(.system(size: 17))
                .padding(.top, 4)
        }
        .multilineTextAlignment(.center)
    }
    
    // MARK: - Buttons
    
    private var buttonSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                makeCard(caption: "Кэшбэк", header: "825 ₽")
                makeCard(caption: "Проценты", header: "4 902 ₽")
            }
            HStack(spacing: 12) {
                makeCard(caption: "Экономия", header: "990 ₽")
                makeCard(caption: "Бонусы", header: "1 112 ₽")
            }
        }
    }
    
    private func makeCard(caption: String, header: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption)
                .font(.system(size: 13, weight: .semibold))
            Text(header)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.Text.primary)
                .particleEffect(fontSize: 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 14, trailing: 20))
        .background(Color.Background.neutral1)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    // MARK: - Bottom
    
    private var bottomSection: some View {
        VStack(spacing: 12) {
            Image(.tShield)
                .resizable()
                .frame(width: 24, height: 24)
            Text("Мы помогаем вам зарабатывать и экономить\nкаждый день. Т-Банк — это про выгоду")
                .font(.system(size: 12))
                .foregroundStyle(Color.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    BenefitsAllTimeView()
}

//
//  BenefitsMainView.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 08.12.2025.
//

import SwiftUI

struct BenefitsMainView: View {
    var body: some View {
        ZStack {
            BenefitsMainBackground()
                .ignoresSafeArea()
            VStack(spacing: .zero) {
                Text("1  990  ₽")
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.Text.primaryOnDark)
                    .particleEffect(fontSize: 76, respectBounds: false)
                    .padding(.top, 48)
                Text("Ваша выгода в этом году")
                    .padding(.top, 2)
                HStack(spacing: 4) {
                    Text("А за все время")
                    Button(action: {}) {
                        allTimeButton
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(Color.Text.secondaryOnDark)
                .padding(.top, 6)
                
                benefitChart
                    .padding(.top, 40)
                benefitDetails
                    .padding(.top, 40)
                
                Spacer()
                
                Text("Как получать больше выгоды")
                    .foregroundStyle(Color.Text.secondaryOnDark)
                cardsStack
                    .padding(.top, 16)
            }
        }
        .foregroundStyle(Color.Text.primaryOnDark)
    }
    
    private var allTimeButton: some View {
        HStack(spacing: 5) {
            Text("8 627 ₽")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.Text.secondaryOnDark)
                .particleEffect(fontSize: 13)
            Image(systemName: "chevron.right.circle.fill")
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundStyle(Color.white.opacity(0.25))
        }
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 6))
        .background(Color.Background.neutral1OnDark)
        .clipShape(Capsule())
    }
    
    // MARK: - Chart
    
    private var benefitChart: some View {
        Image(.benefitsChart)
            .resizable()
            .scaledToFill()
            .frame(height: 118)
    }
    
    // MARK: - Details
    
    private var benefitDetails: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                benefitBadge("Кэшбэк ", sensitive: "22 ₽")
                benefitBadge("Проценты ", sensitive: "100 ₽")
            }
            HStack(spacing: 8) {
                benefitBadge("Экономия ", sensitive: "0 ₽")
                benefitBadge("Бонусы ", sensitive: "0 ₽")
            }
        }
    }
    
    private func benefitBadge(_ text: String, sensitive: String) -> some View {
        HStack(spacing: .zero) {
            Text(text)
            Text(sensitive)
                .foregroundStyle(Color.Text.primaryOnDark)
                .particleEffect(fontSize: 15)
        }
        .font(.system(size: 15, weight: .medium))
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.Background.neutral2OnDark)
        .clipShape(Capsule())
    }
    
    // MARK: - Cards Stack
    
    private var cardsStack: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(white: 0.76))
                .padding(EdgeInsets(top: -15, leading: 40, bottom: 0, trailing: 50))
                .frame(height: 190)
                .rotationEffect(.degrees(2))
            RoundedRectangle(cornerRadius: 22)
                .foregroundStyle(Color(white: 0.9))
                .padding(EdgeInsets(top: -10, leading: 14, bottom: 0, trailing: 14))
                .frame(height: 212)
                .rotationEffect(.degrees(-4.5))
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .foregroundStyle(Color.Background.elevation1)
            HStack(spacing: 16) {
                Image(.benefitsBags)
                    .resizable()
                    .frame(width: 56, height: 56)
                    .background(Color.Background.neutral1)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Покупки")
                        .foregroundStyle(Color.Text.primary)
                    Text("Кэшбэк до 30%")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.Text.secondary)
                }
                Spacer()
            }
            .padding(20)
        }
        .colorScheme(.light)
        .frame(height: 72, alignment: .top)
        .padding(.top, 22)
        .padding(.horizontal, 16)
    }
}

#Preview {
    BenefitsMainView()
}

//
//  EventsAndOperationsView.swift
//  ParticleEffect
//
//  Created by Konstantin Moskalenko on 30.12.2025.
//

import SwiftUI

struct EventsAndOperationsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
//            searchBar
//                .padding(.bottom, 12)
            chipsFilter
                .padding(.top, 8)
            cardsFinanal
                .padding(.top, 20)
            ScrollView(.vertical, showsIndicators: false, content: operationContent)
                .padding(.top, 20)
        }
        .padding(.horizontal, 16)
        .foregroundStyle(Color.Text.primary)
        .background(Color.Background.elevation1.ignoresSafeArea())
    }
    
    // MARK: - Header
    
    private var searchBar: some View {
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
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func chip(label: String, accent: Bool = false, showsDropdown: Bool) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
            if showsDropdown {
                Image(.triangleDown)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
        }
        .padding(EdgeInsets(top: 7, leading: 11, bottom: 7, trailing: showsDropdown ? 7 : 11))
        .foregroundStyle(accent ? Color.Text.primaryOnDark : Color.Text.primary)
        .background(accent ? Color.Background.accent2 : Color.Background.neutral1)
        .clipShape(Capsule())
    }
    
    private var chipsFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "Апрель", accent: true, showsDropdown: true)
                chip(label: "Счета и карты", showsDropdown: true)
                chip(label: "Без переводов", showsDropdown: false)
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
    }
    
    private func card(title: String, description: String, chartSyle: BarChart.Style) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.Text.primary)
                .lineLimit(1)
                .particleEffect(fontSize: 17)
            Text(description)
                .font(.system(size: 15))
            BarChart(style: chartSyle)
                .padding(.top, 12)
        }
        .padding(EdgeInsets(top: 16, leading: 20, bottom: 20, trailing: 20))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.Background.elevation2)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.12), radius: 34, y: 6)
    }
    
    private var cardsFinanal: some View {
        HStack(spacing: 20) {
            card(title: "168 526 ₽", description: "Траты", chartSyle: .spending)
            card(title: "168 526 ₽", description: "Доходы", chartSyle: .income)
        }
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(Color.Text.primary)
    }
    
    // MARK: - Content
    
    private func dayHeader(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
            Spacer()
            Text(value)
                .font(.system(size: 17))
                .foregroundStyle(Color.Text.tertiary)
                .particleEffect(fontSize: 17)
        }
        .padding(.vertical, 12)
    }
    
    private func operationCell(icon: UIImage? = nil,
                               title: String,
                               titleValue: String,
                               titleValueBadges: [CashbackBadge] = [],
                               description: String,
                               descriptionBadges: [CashbackBadge] = [],
                               descriptionValue: String,
                               cashbackBadge: CashbackBadge? = nil,
                               message: (text: String, isIncoming: Bool)? = nil) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(uiImage: icon ?? UIImage())
                .resizable()
                .scaledToFit()
                .background(Color.Background.neutral1)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(title)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(titleValue)
                        .foregroundColor(titleValue.hasPrefix("+")
                                         ? Color.Text.positive
                                         : Color.Text.primary)
                        .particleEffect(fontSize: 17)
                    ForEach(titleValueBadges, id: \.self, content: \.self)
                }
                .font(.system(size: 17))
                
                HStack(spacing: 4) {
                    Text(description)
                    ForEach(descriptionBadges, id: \.self, content: \.self)
                    Spacer()
                    cashbackBadge
                    Text(descriptionValue)
                }
                .font(.system(size: 13))
                .foregroundStyle(Color.Text.secondary)
                
                if let (text, isIncoming) = message {
                    Text(text)
                        .font(.system(size: 17))
                        .foregroundStyle(isIncoming ? Color.Text.primary : Color.Text.primaryOnDark)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(isIncoming ? Color.Background.neutral1 : Color.Background.accent2)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity, alignment: isIncoming ? .leading : .trailing)
                }
            }
        }
        .lineLimit(1)
        .padding(.vertical, 20)
    }
    
    private func operationContent() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            dayHeader(title: "17 октября", value: "−36 294 ₽")
            operationCell(icon: UIImage.Operations.mvideo,
                          title: "М.Видео",
                          titleValue: "−10 990 ₽",
                          titleValueBadges: [.arrowRoundUp, .clockHands],
                          description: "Техника",
                          descriptionBadges: [.receipt, .partCircle],
                          descriptionValue: "Дебетовая карта",
                          cashbackBadge: CashbackBadge(text: "+1 099", size: .small, appearance: .accent1))
            operationCell(icon: UIImage.Operations.drinkit,
                          title: "Дринкит",
                          titleValue: "−326 ₽",
                          titleValueBadges: [.arrowRoundUp],
                          description: "Фастфуд",
                          descriptionBadges: [.receipt],
                          descriptionValue: "All Games",
                          cashbackBadge: CashbackBadge(text: "+3", size: .small, appearance: .lightText))
            operationCell(icon: UIImage.Operations.tbank,
                          title: "Дмитрий Ш.",
                          titleValue: "−10 000 ₽",
                          description: "Переводы",
                          descriptionValue: "Black",
                          message: (text: "С днем рождения!", isIncoming: false))
            operationCell(icon: UIImage.Operations.perekrestok,
                          title: "Перекресток",
                          titleValue: "−5 435,71 ₽",
                          description: "Супермаркеты",
                          descriptionBadges: [.receipt, .partCircle],
                          descriptionValue: "All Games",
                          cashbackBadge: CashbackBadge(text: "+276", size: .small, appearance: .accent1))
            operationCell(icon: UIImage.Operations.lamoda,
                          title: "Lamoda",
                          titleValue: "−20 532 ₽",
                          description: "Одежда и обувь",
                          descriptionBadges: [.receipt],
                          descriptionValue: "Дебетовая карта",
                          cashbackBadge: CashbackBadge(text: "+205", size: .small, appearance: .lightText))
            
            dayHeader(title: "Вчера", value: "−1 682,11 ₽")
            operationCell(icon: UIImage.Operations.pyatyorochka,
                          title: "Пятерочка",
                          titleValue: "−1 012,11 ₽",
                          description: "Супермаркеты",
                          descriptionBadges: [.receipt, .partCircle],
                          descriptionValue: "All Games",
                          cashbackBadge: CashbackBadge(text: "+20", size: .small, appearance: .accent1))
            operationCell(icon: UIImage.Operations.tbank,
                          title: "Алина К.",
                          titleValue: "+500 ₽",
                          description: "Переводы",
                          descriptionValue: "Дебетовая карта",
                          message: (text: "За кофе", isIncoming: true))
            operationCell(icon: UIImage.Operations.sber,
                          title: "Наталья П.",
                          titleValue: "+1 000 ₽",
                          description: "Переводы",
                          descriptionValue: "Дебетовая карта")
            operationCell(icon: UIImage.Operations.yandexTaxi,
                          title: "Яндекс.Такси",
                          titleValue: "−670 ₽",
                          description: "Транспорт",
                          descriptionBadges: [.receipt],
                          descriptionValue: "All Games",
                          cashbackBadge: CashbackBadge(text: "+120", size: .small, appearance: .accent1))
            
            dayHeader(title: "22 апреля", value: "−2 795,97 ₽")
            operationCell(icon: UIImage.Operations.yandexLavka,
                          title: "Яндекс Лавка",
                          titleValue: "−43 ₽",
                          description: "Супермаркеты",
                          descriptionValue: "Дебетовая карта")
            operationCell(icon: UIImage.Operations.yandexLavka,
                          title: "Яндекс Лавка",
                          titleValue: "−2 007 ₽",
                          description: "Супермаркеты",
                          descriptionBadges: [.receipt, .partCircle],
                          descriptionValue: "Дебетовая карта",
                          cashbackBadge: CashbackBadge(text: "+20", size: .small, appearance: .lightText))
            operationCell(icon: UIImage.Operations.supermarket,
                          title: "Festivalnaya 41",
                          titleValue: "−569,97 ₽",
                          description: "Супермаркеты",
                          descriptionBadges: [.receipt],
                          descriptionValue: "Дебетовая карта",
                          cashbackBadge: CashbackBadge(text: "+5", size: .small, appearance: .lightText))
            operationCell(icon: UIImage.Operations.moscowTransport,
                          title: "Московский транспорт",
                          titleValue: "−182 ₽",
                          description: "Местный транспорт",
                          descriptionValue: "Дебетовая карта",
                          cashbackBadge: CashbackBadge(text: "+2", size: .small, appearance: .lightText))
            
            dayHeader(title: "21 апреля", value: "−1 999 ₽")
            operationCell(icon: UIImage.Operations.ozon,
                          title: "Ozon.ru",
                          titleValue: "−1 999 ₽",
                          description: "Маркетплейсы",
                          descriptionBadges: [.partCircle],
                          descriptionValue: "Дебетовая карта",
                          cashbackBadge: CashbackBadge(text: "+10", size: .small, appearance: .lightText))
        }
    }
}

#Preview {
    EventsAndOperationsView()
}

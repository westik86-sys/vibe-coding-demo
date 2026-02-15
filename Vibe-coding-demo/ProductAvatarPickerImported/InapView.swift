import SwiftUI

struct InapView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InapViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("InApp 2.0 Demo")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 40)
                
                Text("Демонстрация InApp сообщений с анимацией")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    // Кнопка показа/скрытия InApp
                    Button(action: {
                        viewModel.showInApp()
                    }) {
                        HStack {
                            Image(systemName: viewModel.isInAppShown ? "xmark.circle.fill" : "bell.badge.fill")
                                .font(.system(size: 20))
                            Text(viewModel.isInAppShown ? "Скрыть InApp" : "Показать InApp")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.isInAppShown ? Color.red : Color.blue)
                        .cornerRadius(16)
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isInAppShown)
                    
                    // Описание жестов
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Возможности:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                        
                        FeatureRow(icon: "hand.tap", text: "Тап - выполнить действие")
                        FeatureRow(icon: "hand.point.up", text: "Свайп вверх - закрыть")
                        FeatureRow(icon: "hand.point.down", text: "Свайп вниз - резинка")
                        FeatureRow(icon: "hand.tap.fill", text: "Долгое нажатие - пауза")
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.03))
                    .cornerRadius(16)
                }
                .padding(.top, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Done action
                }) {
                    Text("Готово")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.black)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackground(
            .ultraThinMaterial,
            for: .navigationBar
        )
        .toolbarColorScheme(.light, for: .navigationBar)
        .preferredColorScheme(.light)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.black.opacity(0.7))
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        InapView()
    }
}

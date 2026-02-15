import SwiftUI
import PhotosUI
import UIKit

struct ProductAvatarView: View {
    @StateObject private var viewModel = ProductAvatarViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var editingText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ScrollView {
                VStack(spacing: 0) {
                    // Avatar
                    avatarView
                        .padding(.top, 24)
                    
                    // Product name
                    Group {
                        if viewModel.isEditingName {
                            TextField("", text: $editingText)
                                .font(.system(size: 20, weight: .bold, design: .default))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .focused($isTextFieldFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    saveProductName()
                                }
                                .onChange(of: editingText) { _ in
                                    if editingText.count > 30 {
                                        editingText = String(editingText.prefix(30))
                                    }
                                }
                                .onChange(of: isTextFieldFocused) { _ in
                                    if !isTextFieldFocused && viewModel.isEditingName {
                                        saveProductName()
                                    }
                                }
                        } else {
                            Text(viewModel.productName)
                                .font(.system(size: 20, weight: .bold, design: .default))
                                .foregroundColor(.black)
                                .onTapGesture {
                                    startEditing()
                                }
                        }
                    }
                    .padding(.top, 36)
                    
                    // Photo picker button
                    photoPickerButton
                        .padding(.top, 38)
                    
                    // Color selector
                    colorSelector
                        .padding(.top, 20)
                    
                    // Emoji picker
                    emojiPicker
                        .id("emojiPicker-\(viewModel.isEditingName)")
                        .padding(.top, 20)
                        .padding(.bottom, 34)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
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
    
    private func startEditing() {
        editingText = viewModel.productName
        viewModel.isEditingName = true
        isTextFieldFocused = true
    }
    
    private func saveProductName() {
        let trimmed = editingText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            viewModel.productName = trimmed
        }
        viewModel.isEditingName = false
        isTextFieldFocused = false
    }
    
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(viewModel.selectedColor.opacity(0.3))
                .frame(width: 140, height: 140)
            
            if let selectedImage = viewModel.selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
            } else {
                Text(viewModel.selectedEmoji)
                    .font(.system(size: 64))
            }
        }
    }
    
    private var photoPickerButton: some View {
        PhotosPicker(selection: $viewModel.selectedPhotoItem,
                    matching: .images) {
            HStack(spacing: 0) {
                Text(viewModel.selectedImage != nil ? "Изменить фото" : "Выбрать фото")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "camera")
                    .font(.system(size: 17))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.03))
            .cornerRadius(24)
        }
        .onChange(of: viewModel.selectedPhotoItem) { _ in
            Task {
                await viewModel.loadSelectedPhoto()
            }
        }
    }
    
    private var colorSelector: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 12
            let horizontalPadding: CGFloat = 16
            let availableWidth = geometry.size.width - (horizontalPadding * 2)
            let circleSize = (availableWidth - (spacing * 6)) / 7
            
            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    ForEach(Array(viewModel.colors.prefix(7).enumerated()), id: \.element) { _, color in
                        ColorCircle(color: color,
                                  isSelected: viewModel.selectedColor == color,
                                  size: circleSize) {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            viewModel.selectedColor = color
                            viewModel.selectedImage = nil
                        }
                    }
                }
                
                HStack(spacing: spacing) {
                    ForEach(Array(viewModel.colors.dropFirst(7).enumerated()), id: \.element) { _, color in
                        ColorCircle(color: color,
                                  isSelected: viewModel.selectedColor == color,
                                  size: circleSize) {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            viewModel.selectedColor = color
                            viewModel.selectedImage = nil
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, horizontalPadding)
        }
        .frame(height: 116)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.03))
        .cornerRadius(24)
    }
    
    private var emojiPicker: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 12
            let horizontalPadding: CGFloat = 16
            let verticalPadding: CGFloat = 16
            let availableWidth = geometry.size.width - (horizontalPadding * 2)
            let itemSize = (availableWidth - (spacing * 5)) / 6
            
            ZStack {
                Color.black.opacity(0.03)
                
                DarkScrollView {
                    VStack(spacing: spacing) {
                        ForEach(0..<14) { row in
                            HStack(spacing: spacing) {
                                ForEach(0..<6) { col in
                                    let index = row * 6 + col
                                    if index < viewModel.emojis.count {
                                        EmojiButton(emoji: viewModel.emojis[index],
                                                  isSelected: viewModel.selectedEmoji == viewModel.emojis[index],
                                                  size: itemSize) {
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred()
                                            viewModel.selectedEmoji = viewModel.emojis[index]
                                            viewModel.selectedImage = nil
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, verticalPadding)
                    .padding(.bottom, verticalPadding)
                    .padding(.horizontal, horizontalPadding)
                    .background(Color.clear)
                }
            }
        }
        .frame(height: 232)
        .frame(maxWidth: .infinity)
        .cornerRadius(24)
        .clipped()
    }
}

struct ColorCircle: View {
    let color: Color
    let isSelected: Bool
    var size: CGFloat = 44
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                
                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 3)
                        .frame(width: size - 6, height: size - 6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct EmojiButton: View {
    let emoji: String
    let isSelected: Bool
    var size: CGFloat = 44
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.white)
                        .frame(width: size, height: size)
                }
                
                Text(emoji)
                    .font(.system(size: size * 0.7))
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }
}

struct DarkScrollView<Content: View>: UIViewControllerRepresentable {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIViewController(context: Context) -> UIScrollViewController<Content> {
        let scrollViewController = UIScrollViewController(rootView: content)
        scrollViewController.scrollView.indicatorStyle = .black
        return scrollViewController
    }
    
    func updateUIViewController(_ uiViewController: UIScrollViewController<Content>, context: Context) {
        uiViewController.hostingController.rootView = content
    }
}

class UIScrollViewController<Content: View>: UIViewController {
    let scrollView = UIScrollView()
    let hostingController: UIHostingController<Content>
    
    init(rootView: Content) {
        self.hostingController = UIHostingController(rootView: rootView)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .black
        view.addSubview(scrollView)
        
        addChild(hostingController)
        hostingController.view.backgroundColor = .clear
        scrollView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
}

#Preview {
    ProductAvatarView()
}

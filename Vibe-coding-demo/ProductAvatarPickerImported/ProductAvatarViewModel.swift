import SwiftUI
import PhotosUI
import Combine

@MainActor
class ProductAvatarViewModel: ObservableObject {
    @Published var selectedColor: Color = Color(red: 0.98, green: 0.73, blue: 0.73)
    @Published var selectedEmoji: String = "🐷"
    @Published var selectedImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var productName: String = "Копилочка"
    @Published var isEditingName: Bool = false
    
    let colors: [Color] = [
        Color(red: 0.4, green: 0.78, blue: 0.98),  // Light blue
        Color(red: 0.67, green: 0.47, blue: 0.98), // Purple
        Color(red: 0.98, green: 0.38, blue: 0.38), // Red
        Color(red: 0.26, green: 0.84, blue: 0.78), // Teal
        Color(red: 0.98, green: 0.73, blue: 0.38), // Orange
        Color(red: 0.73, green: 0.55, blue: 0.98), // Light purple
        Color(red: 0.18, green: 0.69, blue: 0.32), // Green
        
        Color(red: 0.26, green: 0.26, blue: 0.26), // Dark gray
        Color(red: 0.38, green: 0.55, blue: 0.98), // Blue
        Color(red: 0.98, green: 0.65, blue: 0.18), // Amber
        Color(red: 0.47, green: 0.85, blue: 0.47), // Light green
        Color(red: 0.98, green: 0.88, blue: 0.32), // Yellow
        Color(red: 0.98, green: 0.73, blue: 0.73), // Light pink (selected by default)
        Color(red: 0.68, green: 0.85, blue: 0.98)  // Sky blue
    ]
    
    let emojis: [String] = [
        "🐷", "🦆", "🐶", "🐱", "🐻", "🐼",
        "🐨", "🐯", "🦁", "🐮", "🐸", "🐵",
        "🐔", "🐧", "🐦", "🐤", "🦄", "🐴",
        "🐺", "🐗", "🦊", "🦝", "🐰", "🐭",
        "🐹", "🐿️", "🦒", "🐘", "🦏", "🦛",
        "🐪", "🐫", "🦙", "🦘", "🦌", "🐃",
        "🐂", "🐄", "🐎", "🐖", "🐏", "🐑",
        "🦓", "🦍", "🦧", "🐅", "🐆", "🦬",
        "🦣", "🦫", "🦦", "🦥", "🐁", "🐀",
        "🦔", "🐇", "🐩", "🐕", "🦮", "🐕‍🦺",
        "🐈", "🐈‍⬛", "🦜", "🦚", "🦩", "🦢",
        "🦉", "🦤", "🪶", "🐓", "🦃", "🦅",
        "🦆", "🐥", "🐣", "🦇", "🐴", "🦄",
        "🐝", "🦋", "🐛", "🐌", "🐞", "🐜"
    ]
    
    func loadSelectedPhoto() async {
        guard let item = selectedPhotoItem else { return }
        
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedImage = image
            selectedPhotoItem = nil
        }
    }
}

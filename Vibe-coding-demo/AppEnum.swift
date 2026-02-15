import Foundation

/// Central registry of launchable mini-projects.
enum AppProject: String, CaseIterable, Hashable, Identifiable {
    // Imported from product-avatar-picker
    case avatarSettings
    case notificationCenter
    case notificationCenterPulseLike
    case ncInap
    case envelope
    case particleEffectPocMain

    // Add "Project 2" here later, for example:
    // case project2

    var id: String { rawValue }

    var title: String {
        switch self {
        case .avatarSettings:
            return "Avatar Settings"
        case .notificationCenter:
            return "Notification Center"
        case .notificationCenterPulseLike:
            return "Notification Center (Pulse Like)"
        case .ncInap:
            return "NC + InApp"
        case .envelope:
            return "Envelope"
        case .particleEffectPocMain:
            return "particle-effect-poc-main"

        // Add title mapping for "Project 2" here:
        // case .project2: return "Project 2"
        }
    }

    var subtitle: String {
        switch self {
        case .avatarSettings:
            return "Product avatar demo"
        case .notificationCenter:
            return "Dynamic Island-like notification center"
        case .notificationCenterPulseLike:
            return "Pulse-style notification center"
        case .ncInap:
            return "Notification center integrated with InApp"
        case .envelope:
            return "Envelope animation prototype"
        case .particleEffectPocMain:
            return "Particle effects proof of concept"

        // Add subtitle mapping for "Project 2" here:
        // case .project2: return "Your next mini-project"
        }
    }
}

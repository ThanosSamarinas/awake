import Foundation

enum MenuBarIcon: String, CaseIterable, Identifiable {
    case pill = "pill"
    case bolt = "bolt"
    case coffee = "cup.and.saucer"
    case flame = "flame"
    case eye = "eye"
    case hare = "hare"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pill: return "Pill"
        case .bolt: return "Lightning Bolt"
        case .coffee: return "Coffee Cup"
        case .flame: return "Flame"
        case .eye: return "Eye"
        case .hare: return "Rabbit"
        }
    }

    var filledSymbol: String {
        rawValue + ".fill"
    }
}

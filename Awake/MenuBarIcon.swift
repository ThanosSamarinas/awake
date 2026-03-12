import Foundation

enum MenuBarIcon: String, CaseIterable, Identifiable {
    case sun = "sun.max"
    case eye = "eye"
    case bolt = "bolt"
    case lightbulb = "lightbulb"
    case coffee = "cup.and.saucer"
    case sunrise = "sunrise"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sun: return "Sun"
        case .eye: return "Eye"
        case .bolt: return "Lightning Bolt"
        case .lightbulb: return "Lightbulb"
        case .coffee: return "Coffee Cup"
        case .sunrise: return "Sunrise"
        }
    }

    var filledSymbol: String {
        rawValue + ".fill"
    }
}

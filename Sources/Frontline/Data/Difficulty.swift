import Foundation

/// AI difficulty selected in the main menu.
enum Difficulty: Int, CaseIterable {
    case easy, normal, hard

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }

    var next: Difficulty {
        Difficulty(rawValue: (rawValue + 1) % Difficulty.allCases.count) ?? .normal
    }
}

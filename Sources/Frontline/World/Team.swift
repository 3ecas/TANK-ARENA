enum Team: Int, CaseIterable {
    case blue, red, neutral

    static let playable: [Team] = [.blue, .red]

    var opponent: Team {
        switch self {
        case .blue: return .red
        case .red: return .blue
        case .neutral: return .neutral
        }
    }

    func isHostile(to other: Team) -> Bool { self != other }

    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .red: return "Red"
        case .neutral: return "Neutral"
        }
    }
}

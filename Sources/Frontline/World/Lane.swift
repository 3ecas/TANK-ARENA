enum Lane: Int, CaseIterable {
    case top, mid, bot

    var displayName: String {
        switch self {
        case .top: return "Top"
        case .mid: return "Mid"
        case .bot: return "Bot"
        }
    }
}

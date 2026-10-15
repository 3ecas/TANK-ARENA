/// How a battle ended.
enum MatchResult {
    case victory(Team)
    case draw

    var winner: Team? {
        if case .victory(let team) = self { return team }
        return nil
    }
}

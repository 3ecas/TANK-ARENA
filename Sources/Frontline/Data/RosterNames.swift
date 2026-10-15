/// Callsigns for the 50 soldiers.
enum RosterNames {
    static let blue = [
        "You", "Hawk", "Rook", "Echo", "Bishop", "Falcon", "Sparrow", "Atlas", "Bear", "Cobra",
        "Delta", "Frost", "Grizzly", "Hunter", "Iron", "Jackal", "Kodiak", "Lynx", "Maverick", "Nomad",
        "Onyx", "Patriot", "Ranger", "Sarge", "Titan",
    ]
    static let red = [
        "Viper", "Ghost", "Raven", "Saber", "Wolf", "Ash", "Blaze", "Crow", "Dagger", "Fang",
        "Gunner", "Havoc", "Jinx", "Knight", "Lancer", "Mamba", "Nova", "Outlaw", "Phantom", "Reaper",
        "Scorpion", "Talon", "Venom", "Wraith", "Zero",
    ]

    static func name(team: Team, index: Int) -> String {
        let list = team == .blue ? blue : red
        return index < list.count ? list[index] : "\(team.displayName)-\(index + 1)"
    }
}

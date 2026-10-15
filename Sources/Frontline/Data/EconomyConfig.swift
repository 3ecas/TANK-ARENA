import CoreGraphics

enum EconomyConfig {
    static let passiveGoldPerSecond: CGFloat = 2.5
    /// Heroes within this radius of a dying enemy share its XP.
    static let xpShareRadius: CGFloat = 1000
    static let heroKillGold = 300
    static let heroKillGoldPerLevel = 15
    static let assistGold = 120
    static let assistWindow: CGFloat = 10
    static let heroKillXpBase: CGFloat = 150
    static let heroKillXpPerLevel: CGFloat = 30
    static let objectiveGold = 120

    // Command points
    static let maxCommandPoints = 10
    static let cpPerKill = 2
    static let cpPerAssist = 1
    static let cpPerObjective = 2
    static let cpPerStructure = 1
    static let cpPassiveInterval: CGFloat = 60
}

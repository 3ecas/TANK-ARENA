import CoreGraphics

/// General rules of the 25 vs 25 battle.
enum GameConfig {
    static let teamSize = 25
    static let maxHp: CGFloat = 100
    /// Each soldier can come back once after dying.
    static let respawnsPerSoldier = 1
    static let respawnDelay: CGFloat = 5
    static let spawnProtection: CGFloat = 2
    static let soldierRadius: CGFloat = 12
    /// Walking speed (points per second) before weapon weight.
    static let walkSpeed: CGFloat = 118
    /// How far a soldier can see (line of sight is still required).
    static let visionRange: CGFloat = 1050
    static let visionUpdateInterval: CGFloat = 0.1
    /// Shots are less accurate while moving.
    static let movingSpreadMultiplier: CGFloat = 1.8
    static let weaponSwitchTime: CGFloat = 0.35

    // Knife (F)
    static let knifeRange: CGFloat = 50
    static let knifeArc: CGFloat = 1.5
    static let knifeDamage: CGFloat = 55
    static let backstabDamage: CGFloat = 100
    static let knifeCooldown: CGFloat = 0.7

    // Navigation
    static let navCellSize: CGFloat = 20
    static let navPadding: CGFloat = 10
}

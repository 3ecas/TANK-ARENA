import CoreGraphics

/// General gameplay constants.
enum GameConfig {
    static let recallTime: CGFloat = 5
    /// Fraction of max HP healed per second inside your own base.
    static let baseHealRate: CGFloat = 0.12
    static let visionUpdateInterval: CGFloat = 0.1
    static let visionCellSize: CGFloat = 40
    static let spatialCellSize: CGFloat = 200
    /// Right-click snap radius around the cursor.
    static let targetSnapRadius: CGFloat = 80
    /// A locked target is dropped when farther than range * this factor.
    static let targetDropFactor: CGFloat = 1.6
    static let supplyDropDelay: CGFloat = 1.5
    static let stimHpCost: CGFloat = 30
    static let dashDuration: CGFloat = 0.22
    /// Built-in combat roll on F.
    static let dodgeDistance: CGFloat = 240
    static let dodgeCooldown: CGFloat = 8
    /// Right-click snap radius for picking an enemy to attack.
    static let attackClickRadius: CGFloat = 60
    static let teamSize = 5
}

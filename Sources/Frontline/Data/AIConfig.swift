import CoreGraphics

/// Bot tuning ("medium-hard"): quick reactions, decent aim, uses grenades.
enum AIConfig {
    static let thinkInterval: CGFloat = 0.18
    /// Delay between spotting a new enemy and opening fire.
    static let reactionTime: CGFloat = 0.3
    /// Aim error in points: base + per point of distance.
    static let aimErrorBase: CGFloat = 12
    static let aimErrorPerDistance: CGFloat = 0.035
    /// Radians per second bots can turn their aim.
    static let turnRate: CGFloat = 9
    /// Bots only fire when their aim is within this angle of the target.
    static let fireAngleTolerance: CGFloat = 0.12
    /// Chance per think step to throw a grenade when a good opportunity exists.
    static let grenadeChance: CGFloat = 0.22
    static let grenadeMinDistance: CGFloat = 170
    /// How long bots remember where they last saw an enemy.
    static let huntMemory: CGFloat = 4
    static let strafeIntervalMin: CGFloat = 0.5
    static let strafeIntervalMax: CGFloat = 1.3
    /// Bots try to fight at this fraction of their weapon range.
    static let preferredRangeFraction: CGFloat = 0.55
    /// Reload when the magazine falls below this fraction and nobody is in sight.
    static let reloadThreshold: CGFloat = 0.35
}

import CoreGraphics

/// Timing of telegraphed call-ins.
struct StrikeTiming {
    var warning: CGFloat
    var impacts: Int
    var interval: CGFloat
    var impactRadius: CGFloat
}

/// Tuning for ability effects that is not per-rank.
enum StrikeConfig {
    static let strafing = StrikeTiming(warning: 1.4, impacts: 8, interval: 0.12, impactRadius: 60)
    static let carpet = StrikeTiming(warning: 2.2, impacts: 18, interval: 0.1, impactRadius: 110)
    static let artillery = StrikeTiming(warning: 1.6, impacts: 7, interval: 0.3, impactRadius: 95)
    /// EMP impact radius comes from the ability radius.
    static let emp = StrikeTiming(warning: 1.0, impacts: 1, interval: 0, impactRadius: 0)
    /// Call-ins deal reduced damage to structures.
    static let structureMultiplier: CGFloat = 0.4
    static let empSlow: CGFloat = 0.45

    static let grenadeSpeed: CGFloat = 650
    static let shieldOffset: CGFloat = 40
    static let medkitAllyShare: CGFloat = 0.5
    static let stimSpeedBoost: CGFloat = 0.25
}

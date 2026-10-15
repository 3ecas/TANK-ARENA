import CoreGraphics

enum GrenadeType: CaseIterable {
    case frag, flash, stun

    var displayName: String {
        switch self {
        case .frag: return "Frag"
        case .flash: return "Flashbang"
        case .stun: return "Stun"
        }
    }
}

enum GrenadeConfig {
    static let maxThrowDistance: CGFloat = 520
    static let throwSpeed: CGFloat = 620
    static let fuse: CGFloat = 1.6
    static let radius: CGFloat = 4
    static let bounceDamping: CGFloat = 0.45

    static let fragRadius: CGFloat = 170
    static let fragMaxDamage: CGFloat = 120
    static let fragMinDamage: CGFloat = 15

    static let flashRadius: CGFloat = 480
    static let flashMaxDuration: CGFloat = 3.2

    static let stunRadius: CGFloat = 210
    static let stunDuration: CGFloat = 2.6
    /// Speed reduction while stunned (stunned soldiers also cannot shoot).
    static let stunSlow: CGFloat = 0.65
}

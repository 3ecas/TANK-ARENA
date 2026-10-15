import CoreGraphics

enum SummonType {
    case tank, squad, helicopter, sentry
}

enum SummonConfig {
    static func cap(_ type: SummonType) -> Int {
        switch type {
        case .tank: return 1
        case .squad: return 2
        case .helicopter: return 1
        case .sentry: return 2
        }
    }

    /// Distance squads / helicopters keep from their owner.
    static let followDistance: CGFloat = 110
    /// Summons engage enemies within this radius of their owner.
    static let engageRadius: CGFloat = 420
    /// Followers hand off to lane AI when the owner is farther than this.
    static let leashDistance: CGFloat = 1600
    /// Delay between the call-in and the tank arriving.
    static let tankDropDelay: CGFloat = 1.2
    /// Helicopter height (shadow offset).
    static let helicopterAltitude: CGFloat = 26
}

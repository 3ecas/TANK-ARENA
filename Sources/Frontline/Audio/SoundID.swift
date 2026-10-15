import Foundation

enum SoundID: CaseIterable {
    case rifle, shotgun, sniper, lmg, rocket, cannon
    case explosionSmall, explosionBig, emp
    case click, levelUp, purchase, error, alert, capture, heal

    /// Minimum seconds between two plays of the same sound (prevents noise walls).
    var minInterval: TimeInterval {
        switch self {
        case .rifle, .lmg: return 0.035
        case .explosionSmall: return 0.06
        case .explosionBig: return 0.09
        case .alert: return 0.8
        default: return 0.05
        }
    }
}

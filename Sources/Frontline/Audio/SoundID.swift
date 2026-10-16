import Foundation

enum SoundID: CaseIterable {
    case rifle, smg, rocket, pistol
    case explosion, flash, stun, knife, reload, hit, death
    case click, error

    /// Minimum seconds between two plays of the same sound (prevents noise walls with 50 soldiers).
    var minInterval: TimeInterval {
        switch self {
        case .rifle, .smg: return 0.03
        case .pistol, .rocket: return 0.04
        case .hit: return 0.05
        default: return 0.06
        }
    }
}

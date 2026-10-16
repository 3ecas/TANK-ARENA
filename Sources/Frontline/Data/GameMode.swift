import CoreGraphics

/// The two ways to play, both on a generated office floor. The player's side (attack or defence) is random.
enum GameMode {
    /// 5 vs 5, one life: attackers carry one bomb and plant it on A or B; 45 s fuse; defenders defuse.
    case bomb
    /// 16 vs 16 with respawns: two stations, A and B. Any attacker can arm either one; attackers must
    /// destroy both. Defenders defuse armed stations and win when the attackers run out of tickets.
    case rush

    var displayName: String {
        switch self {
        case .bomb: return "Bomb"
        case .rush: return "Rush"
        }
    }

    var teamSize: Int {
        switch self {
        case .bomb: return 5
        case .rush: return 16
        }
    }

    /// Respawns per soldier (Rush: effectively unlimited; attackers pay a ticket each time).
    var respawns: Int {
        switch self {
        case .bomb: return 0
        case .rush: return 100_000
        }
    }

    var style: OfficeStyle {
        switch self {
        case .bomb: return OfficeConfig.bombStyle
        case .rush: return OfficeConfig.rushStyle
        }
    }
}

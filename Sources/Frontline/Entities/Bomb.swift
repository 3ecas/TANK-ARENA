import CoreGraphics

enum BombState {
    /// Rush station waiting to be armed.
    case idle
    /// Carried by an attacker (soldier id) — bomb mode.
    case carried(by: Int)
    /// Lying on the ground; any attacker can pick it up — bomb mode.
    case dropped
    /// Armed and ticking.
    case planted
    /// Defused for good (bomb mode; a defused rush station goes back to idle).
    case defused
    case exploded
}

/// A bomb: the single carried bomb of bomb mode, or one fixed station per site in rush.
@MainActor
final class Bomb {
    var state: BombState
    /// Ground position (dropped / planted / station); follows the carrier while carried.
    var position: CGPoint
    /// Site it was planted on (a rush station always belongs to its site).
    var site: BombSite?
    /// Seconds until it explodes once planted.
    var fuseLeft = BombConfig.fuseTime
    /// 0...1 progress of the current plant / defuse, and who is defusing.
    var plantProgress: CGFloat = 0
    var defuseProgress: CGFloat = 0
    var defuserId: Int?

    /// Bomb-mode bomb, handed to a carrier by BattleSetup.
    init(carrier: Int, position: CGPoint) {
        state = .carried(by: carrier)
        self.position = position
    }

    /// Rush station standing on a site.
    init(station site: BombSite) {
        state = .idle
        position = site.center
        self.site = site
    }

    var carrierId: Int? {
        if case .carried(let id) = state { return id }
        return nil
    }

    var isIdle: Bool {
        if case .idle = state { return true }
        return false
    }

    var isDropped: Bool {
        if case .dropped = state { return true }
        return false
    }

    var isPlanted: Bool {
        if case .planted = state { return true }
        return false
    }

    var isExploded: Bool {
        if case .exploded = state { return true }
        return false
    }
}

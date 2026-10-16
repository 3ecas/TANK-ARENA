import CoreGraphics

enum BombState {
    /// Carried by an attacker (soldier id).
    case carried(by: Int)
    /// Lying on the ground; any attacker can pick it up.
    case dropped
    /// Ticking on a site.
    case planted
    case defused
    case exploded
}

/// The single bomb of the round.
@MainActor
final class Bomb {
    var state: BombState
    /// Ground position (dropped / planted); follows the carrier while carried.
    var position: CGPoint
    /// Site it was planted on.
    var site: BombSite?
    /// Seconds until it explodes once planted.
    var fuseLeft = BombConfig.fuseTime
    /// 0...1 progress of the current plant / defuse, and who is doing it.
    var plantProgress: CGFloat = 0
    var defuseProgress: CGFloat = 0
    var defuserId: Int?

    init(carrier: Int, position: CGPoint) {
        state = .carried(by: carrier)
        self.position = position
    }

    var carrierId: Int? {
        if case .carried(let id) = state { return id }
        return nil
    }

    var isDropped: Bool {
        if case .dropped = state { return true }
        return false
    }

    var isExploded: Bool {
        if case .exploded = state { return true }
        return false
    }

    var isPlanted: Bool {
        if case .planted = state { return true }
        return false
    }
}

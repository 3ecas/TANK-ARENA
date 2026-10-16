import CoreGraphics

/// A box dropped by a medic (health) or engineer (ammo) that supplies teammates standing near it.
@MainActor
final class SupplyBox {
    enum Kind {
        case health, ammo
    }

    let id: Int
    let kind: Kind
    let team: Team
    let position: CGPoint
    var timeLeft = ClassConfig.boxLifetime

    init(id: Int, kind: Kind, team: Team, position: CGPoint) {
        self.id = id
        self.kind = kind
        self.team = team
        self.position = position
    }
}

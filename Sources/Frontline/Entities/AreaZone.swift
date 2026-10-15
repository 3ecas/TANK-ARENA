import CoreGraphics

enum ZoneKind {
    case smoke, shieldDome, supplyCrate, uavReveal
}

/// Persistent area effects created by abilities.
@MainActor
final class AreaZone {
    let id: Int
    let team: Team
    let kind: ZoneKind
    let center: CGPoint
    let radius: CGFloat
    let totalDuration: CGFloat
    var remaining: CGFloat
    /// Time before the zone becomes active (supply crate falling).
    var armingDelay: CGFloat
    /// Shield HP or heal amount depending on kind.
    var value: CGFloat
    /// Units that already used this zone (supply crates).
    var usedBy = Set<Int>()
    var isDone = false

    init(id: Int, team: Team, kind: ZoneKind, center: CGPoint, radius: CGFloat, duration: CGFloat,
         value: CGFloat = 0, armingDelay: CGFloat = 0) {
        self.id = id
        self.team = team
        self.kind = kind
        self.center = center
        self.radius = radius
        self.totalDuration = duration
        self.remaining = duration
        self.value = value
        self.armingDelay = armingDelay
    }

    var isActive: Bool { armingDelay <= 0 && !isDone }

    func contains(_ p: CGPoint) -> Bool {
        p.distanceSquared(to: center) <= radius * radius
    }
}

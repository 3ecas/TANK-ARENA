import CoreGraphics

/// Target validity and neighbour queries shared by brains, combat and controllers.
@MainActor
final class TargetingSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    /// Whether `attacker` may shoot `target` right now (alive, hostile, visible, reachable).
    func canTarget(_ attacker: Entity, _ target: Entity?) -> Bool {
        guard let target = target, target.isAlive, !target.isRemoved, target !== attacker else { return false }
        guard attacker.team.isHostile(to: target.team) else { return false }
        if target.isFlying && !(attacker.attack?.canHitAir ?? true) { return false }
        return ctx.vision.canSee(attacker.team, target)
    }

    func inRange(_ attacker: Entity, _ target: Entity, range: CGFloat) -> Bool {
        attacker.position.distance(to: target.position) <= range + target.radius
    }

    /// Nearest valid target around `center` (defaults to the attacker's position).
    func nearestTarget(for attacker: Entity, within radius: CGFloat, includeNeutral: Bool,
                       around center: CGPoint? = nil, preferNonHeroes: Bool = false) -> Entity? {
        let origin = center ?? attacker.position
        var best: Entity?
        var bestScore = CGFloat.greatestFiniteMagnitude
        for candidate in ctx.world.grid.query(center: origin, radius: radius) {
            if candidate.team == .neutral && !includeNeutral { continue }
            guard canTarget(attacker, candidate) else { continue }
            var score = candidate.position.distanceSquared(to: origin)
            if preferNonHeroes && candidate is Hero { score += 1_000_000_000 }
            if score < bestScore {
                bestScore = score
                best = candidate
            }
        }
        return best
    }

    /// Live hostile entities near a point that `team` can see.
    func enemies(of team: Team, near point: CGPoint, radius: CGFloat, includeNeutral: Bool = false) -> [Entity] {
        ctx.world.grid.query(center: point, radius: radius).filter { e in
            e.team != team && (includeNeutral || e.team != .neutral) && ctx.vision.canSee(team, e)
        }
    }

    func allies(of team: Team, near point: CGPoint, radius: CGFloat) -> [Entity] {
        ctx.world.grid.query(center: point, radius: radius).filter { $0.team == team }
    }

    /// Hostile entity closest to a point (cursor snapping).
    func enemyClosest(to point: CGPoint, radius: CGFloat, viewer: Entity) -> Entity? {
        var best: Entity?
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for candidate in ctx.world.grid.query(center: point, radius: radius) where canTarget(viewer, candidate) {
            let d = candidate.position.distance(to: point) - candidate.radius
            if d < bestDistance {
                bestDistance = d
                best = candidate
            }
        }
        return best
    }
}

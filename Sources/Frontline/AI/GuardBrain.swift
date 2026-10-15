import CoreGraphics

/// Stationary guns (sentry turrets): shoot the nearest hostile in range.
@MainActor
final class GuardBrain: UnitBrain {
    private var retargetTimer: CGFloat = 0

    func update(_ entity: Entity, ctx: GameContext, dt: CGFloat) {
        guard let range = entity.attack?.range else { return }
        retargetTimer -= dt
        if let current = ctx.world.entity(entity.targetId), ctx.targeting.canTarget(entity, current),
           ctx.targeting.inRange(entity, current, range: range), retargetTimer > 0 {
            return
        }
        retargetTimer = 0.4
        entity.targetId = ctx.targeting.nearestTarget(for: entity, within: range, includeNeutral: true)?.id
    }
}

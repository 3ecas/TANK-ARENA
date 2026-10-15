import CoreGraphics

/// Neutral mercenaries / depot guardian: idle at home, retaliate, leash back and heal.
@MainActor
final class CampBrain: UnitBrain {
    let home: CGPoint
    private let leash: CGFloat
    private var returning = false

    init(home: CGPoint, leash: CGFloat) {
        self.home = home
        self.leash = leash
    }

    func update(_ entity: Entity, ctx: GameContext, dt: CGFloat) {
        let distanceHome = entity.position.distance(to: home)
        if returning {
            entity.targetId = nil
            entity.hp = Swift.min(entity.maxHp, entity.hp + entity.maxHp * 0.25 * dt)
            BrainHelpers.move(entity, toward: home, ctx: ctx, stopDistance: 12)
            if distanceHome < 20 {
                returning = false
                entity.recentHeroAttackers.removeAll()
            }
            return
        }
        if distanceHome > leash {
            returning = true
            entity.targetId = nil
            return
        }
        var target = ctx.world.entity(entity.targetId)
        if target == nil || !ctx.targeting.canTarget(entity, target) {
            target = ctx.world.entity(entity.lastAttackerId)
            if let candidate = target, !ctx.targeting.canTarget(entity, candidate)
                || candidate.position.distance(to: home) > leash + 200 {
                target = nil
                entity.lastAttackerId = nil
            }
            entity.targetId = target?.id
        }
        if let target = target, entity.targetId != nil {
            BrainHelpers.engage(entity, target: target, ctx: ctx)
        } else {
            BrainHelpers.move(entity, toward: home, ctx: ctx, stopDistance: 30)
            if distanceHome < 40 { entity.hp = Swift.min(entity.maxHp, entity.hp + entity.maxHp * 0.05 * dt) }
        }
    }
}

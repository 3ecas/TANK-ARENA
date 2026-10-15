import CoreGraphics

/// Bunkers / HQ: prioritise troops and summons, but switch to a hero who attacks an allied hero.
@MainActor
final class StructureBrain: UnitBrain {
    private var forcedTargetId: Int?
    private var forcedTime: CGFloat = 0
    private var retargetTimer: CGFloat = 0

    func forceTarget(_ id: Int, duration: CGFloat) {
        forcedTargetId = id
        forcedTime = duration
    }

    func update(_ entity: Entity, ctx: GameContext, dt: CGFloat) {
        guard let range = entity.attack?.range else { return }
        forcedTime -= dt
        retargetTimer -= dt

        if forcedTime > 0, let forced = ctx.world.entity(forcedTargetId),
           ctx.targeting.canTarget(entity, forced), ctx.targeting.inRange(entity, forced, range: range) {
            entity.targetId = forced.id
            return
        }
        forcedTargetId = nil

        if let current = ctx.world.entity(entity.targetId), ctx.targeting.canTarget(entity, current),
           ctx.targeting.inRange(entity, current, range: range), retargetTimer > 0 {
            return
        }
        retargetTimer = 0.5
        let nonHero = ctx.targeting.nearestTarget(for: entity, within: range, includeNeutral: false,
                                                  preferNonHeroes: true)
        entity.targetId = nonHero?.id
    }
}

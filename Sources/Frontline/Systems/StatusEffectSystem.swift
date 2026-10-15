import CoreGraphics

/// Ticks buff / debuff timers and applies heal-over-time.
@MainActor
final class StatusEffectSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        for entity in ctx.world.entities where entity.isAlive {
            entity.timeSinceShot += dt
            if entity.status.healTime > 0 {
                let amount = entity.status.healPerSecond * Swift.min(dt, entity.status.healTime)
                entity.hp = Swift.min(entity.maxHp, entity.hp + amount)
            }
            entity.status.tick(dt)
        }
    }
}

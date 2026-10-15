import CoreGraphics

/// Passive regeneration and the healing fountain inside each base.
@MainActor
final class HealthSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        let map = ctx.world.map
        for entity in ctx.world.entities where entity.isAlive && entity.hp < entity.maxHp {
            var regen = entity.hpRegen
            if let hero = entity as? Hero, map.isInBase(hero.position, team: hero.team) {
                regen += hero.maxHp * GameConfig.baseHealRate
            }
            if regen > 0 {
                entity.hp = Swift.min(entity.maxHp, entity.hp + regen * dt)
            }
        }
    }
}

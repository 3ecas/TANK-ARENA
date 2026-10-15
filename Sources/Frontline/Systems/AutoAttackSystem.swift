import CoreGraphics

/// Hero weapons: target lock, fire rate, magazine and automatic reload.
@MainActor
final class AutoAttackSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        for hero in ctx.world.heroes where hero.isAlive {
            if let target = ctx.world.entity(hero.targetId), target.isAlive {
                hero.aimAngle = (target.position - hero.position).angle
            } else if hero.velocity.lengthSquared > 1 {
                hero.aimAngle = hero.velocity.angle
            }
            hero.bodyAngle = hero.aimAngle
            hero.attackCooldown = Swift.max(0, hero.attackCooldown - dt)

            if hero.reloadTimer > 0 {
                hero.reloadTimer -= dt
                if hero.reloadTimer <= 0 {
                    hero.reloadTimer = 0
                    hero.ammo = hero.stats.magSize
                }
                continue
            }
            if hero.ammo <= 0 {
                hero.reloadTimer = hero.stats.reloadTime
                continue
            }
            guard let target = ctx.world.entity(hero.targetId), ctx.targeting.canTarget(hero, target) else {
                hero.targetId = nil
                hero.chasesTarget = false
                continue
            }
            let distance = hero.position.distance(to: target.position) - target.radius
            // Right-click targets are chased; auto-acquired ones are dropped when they leave range.
            if !hero.chasesTarget && distance > hero.stats.range * GameConfig.targetDropFactor {
                hero.targetId = nil
                continue
            }
            guard distance <= hero.stats.range, hero.attackCooldown <= 0, !hero.status.isStunned,
                  !hero.status.isDashing, let attack = hero.attack else { continue }
            shoot(hero, at: target, attack: attack)
        }
    }

    private func shoot(_ hero: Hero, at target: Entity, attack: AttackStats) {
        if hero.isRecalling { ctx.recall.cancel(hero) }
        ctx.combat.fire(from: hero, at: target, attack: attack, damage: hero.stats.damage)
        // Shotguns: extra pellet tracers (damage is already included in the main shot).
        if hero.stats.pellets > 1 {
            let distance = hero.position.distance(to: target.position)
            for _ in 1..<hero.stats.pellets {
                let angle = hero.aimAngle + CGFloat.random(in: -hero.stats.spread...hero.stats.spread)
                let end = hero.position + CGPoint(angle: angle, length: distance)
                ctx.bus.publish(.shotFired(sourceId: hero.id, from: hero.position, to: end, kind: .bullet))
            }
        }
        hero.attackCooldown = hero.stats.fireInterval / hero.status.fireRateMultiplier
        hero.ammo -= 1
        if hero.ammo <= 0 {
            hero.reloadTimer = hero.stats.reloadTime
        }
    }
}

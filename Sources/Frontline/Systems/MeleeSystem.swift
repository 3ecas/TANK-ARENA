import CoreGraphics

/// Knife attacks (F): short arc in front of the soldier, backstabs are lethal.
@MainActor
final class MeleeSystem {
    unowned let ctx: BattleContext
    private let damage: DamageSystem

    init(ctx: BattleContext, damage: DamageSystem) {
        self.ctx = ctx
        self.damage = damage
    }

    func update(dt: CGFloat) {
        for soldier in ctx.world.soldiers {
            soldier.knifeCooldown = Swift.max(0, soldier.knifeCooldown - dt)
            soldier.knifeSwing = Swift.max(0, soldier.knifeSwing - dt)
        }
    }

    /// Swings the knife. Returns false while on cooldown.
    @discardableResult
    func swing(_ soldier: Soldier) -> Bool {
        guard soldier.isAlive, soldier.knifeCooldown <= 0, !soldier.isStunned else { return false }
        soldier.knifeCooldown = GameConfig.knifeCooldown
        soldier.knifeSwing = 0.2
        var hitSomeone = false
        for enemy in ctx.world.soldiers where enemy.isAlive && enemy.team != soldier.team {
            let delta = enemy.position - soldier.position
            guard delta.length <= GameConfig.knifeRange + enemy.radius else { continue }
            let offAngle = abs(Angle.normalize(delta.angle - soldier.facing))
            guard offAngle <= GameConfig.knifeArc / 2,
                  ctx.world.map.hasLineOfSight(soldier.position, enemy.position) else { continue }
            // Stabbing someone who faces away is lethal.
            let facingAway = abs(Angle.normalize(enemy.facing - delta.angle)) < 1.0
            let amount = facingAway ? GameConfig.backstabDamage : GameConfig.knifeDamage
            damage.apply(amount, to: enemy, from: soldier, weaponName: "Knife")
            hitSomeone = true
        }
        ctx.bus.publish(.knifeSwing(soldierId: soldier.id, position: soldier.position, angle: soldier.facing,
                                    hit: hitSomeone))
        return true
    }
}

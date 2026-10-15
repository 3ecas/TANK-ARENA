import CoreGraphics

/// Fires the weapons of all non-hero units and provides the shared `fire` routine.
@MainActor
final class CombatSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        for entity in ctx.world.entities where entity.isAlive && !(entity is Hero) {
            guard let attack = entity.attack else { continue }
            entity.attackCooldown = Swift.max(0, entity.attackCooldown - dt)
            guard !entity.status.isStunned,
                  let target = ctx.world.entity(entity.targetId),
                  ctx.targeting.canTarget(entity, target),
                  ctx.targeting.inRange(entity, target, range: attack.range) else { continue }
            let desired = (target.position - entity.position).angle
            entity.aimAngle = Angle.approach(entity.aimAngle, desired, maxStep: 6 * dt)
            if entity.attackCooldown <= 0 {
                fire(from: entity, at: target, attack: attack, damage: attack.damage)
                entity.attackCooldown = attack.interval / entity.status.fireRateMultiplier
            }
        }
    }

    /// Shoots one round: spawns a projectile or applies hitscan damage with a tracer.
    func fire(from attacker: Entity, at target: Entity, attack: AttackStats, damage: CGFloat) {
        let direction = target.position - attacker.position
        attacker.aimAngle = direction.angle
        attacker.timeSinceShot = 0
        let muzzle = attacker.position + CGPoint(angle: attacker.aimAngle, length: attacker.radius + 6)

        if attack.projectileSpeed > 0 {
            let projectile = Projectile(
                id: ctx.world.makeId(), team: attacker.team, sourceId: attacker.id, kind: attack.projectile,
                from: muzzle, targetId: target.id, targetPoint: target.position, speed: attack.projectileSpeed,
                damage: damage, splashRadius: attack.splashRadius, vsArmored: attack.vsArmored)
            ctx.world.addProjectile(projectile)
            ctx.bus.publish(.shotFired(sourceId: attacker.id, from: muzzle, to: target.position,
                                       kind: attack.projectile))
            return
        }

        if let dome = ctx.zones.blockingDome(attackerTeam: attacker.team, from: attacker.position,
                                             to: target.position) {
            dome.value -= damage
            let edge = dome.center + (attacker.position - dome.center).normalized * dome.radius
            ctx.bus.publish(.shotFired(sourceId: attacker.id, from: muzzle, to: edge, kind: .bullet))
            return
        }
        ctx.bus.publish(.shotFired(sourceId: attacker.id, from: muzzle, to: target.position, kind: .bullet))
        ctx.damage.apply(DamageInfo(amount: damage, sourceId: attacker.id, team: attacker.team,
                                    vsArmored: attack.vsArmored), to: target)
    }
}

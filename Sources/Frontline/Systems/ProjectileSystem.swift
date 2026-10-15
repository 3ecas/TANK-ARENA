import CoreGraphics

/// Moves projectiles, resolves impacts and splash damage.
@MainActor
final class ProjectileSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        let world = ctx.world
        for projectile in world.projectiles where !projectile.isDone {
            if let target = world.entity(projectile.targetId), target.isAlive, !target.isRemoved {
                projectile.targetPoint = target.position
            }
            let step = projectile.speed * dt
            let next = projectile.position.moved(toward: projectile.targetPoint, maxDistance: step)
            if let dome = ctx.zones.blockingDome(attackerTeam: projectile.team, from: projectile.position, to: next) {
                dome.value -= projectile.damage
                projectile.isDone = true
                ctx.bus.publish(.projectileImpact(position: next, kind: projectile.kind))
                continue
            }
            projectile.position = next
            if projectile.position.distanceSquared(to: projectile.targetPoint) < 4 {
                impact(projectile)
            }
        }
    }

    private func impact(_ projectile: Projectile) {
        projectile.isDone = true
        let info = DamageInfo(amount: projectile.damage, sourceId: projectile.sourceId, team: projectile.team,
                              vsArmored: projectile.vsArmored)
        if projectile.splashRadius > 0 {
            ctx.damage.applyArea(center: projectile.position, radius: projectile.splashRadius, info: info,
                                 hitsAir: projectile.kind != .shell)
            let big = projectile.kind == .grenade || projectile.splashRadius >= 80
            ctx.bus.publish(.explosion(position: projectile.position, radius: projectile.splashRadius, big: big))
        } else if let target = ctx.world.entity(projectile.targetId), target.isAlive {
            ctx.damage.apply(info, to: target)
        }
        ctx.bus.publish(.projectileImpact(position: projectile.position, kind: projectile.kind))
    }
}

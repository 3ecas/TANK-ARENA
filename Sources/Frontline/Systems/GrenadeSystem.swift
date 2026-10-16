import CoreGraphics

/// Throwing grenades, their flight (bouncing off walls) and detonation effects.
@MainActor
final class GrenadeSystem {
    unowned let ctx: BattleContext
    private let damage: DamageSystem

    init(ctx: BattleContext, damage: DamageSystem) {
        self.ctx = ctx
        self.damage = damage
    }

    /// Throws the soldier's grenade toward `target` (clamped to max distance). Returns false if none left.
    @discardableResult
    func throwGrenade(_ soldier: Soldier, at target: CGPoint) -> Bool {
        guard soldier.isAlive, !soldier.isStunned, !soldier.isMounted, soldier.grenadeCount > 0,
              let type = soldier.grenade else { return false }
        soldier.grenadeCount -= 1
        let aim = target.limited(from: soldier.position, maxDistance: GrenadeConfig.maxThrowDistance)
        let start = soldier.position + (aim - soldier.position).normalized * (soldier.radius + 4)
        let grenade = Grenade(id: ctx.world.makeId(), type: type, team: soldier.team, ownerId: soldier.id,
                              from: start, to: aim)
        ctx.world.grenades.append(grenade)
        ctx.bus.publish(.grenadeThrown(soldierId: soldier.id, type: type))
        return true
    }

    func update(dt: CGFloat) {
        for grenade in ctx.world.grenades where !grenade.isDone {
            move(grenade, dt: dt)
            grenade.fuse -= dt
            if grenade.fuse <= 0 { detonate(grenade) }
        }
    }

    private func move(_ grenade: Grenade, dt: CGFloat) {
        guard grenade.remainingDistance > 0 else { return }
        let map = ctx.world.map
        let step = Swift.min(grenade.velocity.length * dt, grenade.remainingDistance)
        let direction = grenade.velocity.normalized
        var next = grenade.position + direction * step
        if map.isInsideObstacle(next, padding: GrenadeConfig.radius) || !map.bounds.contains(next) {
            // Bounce: reflect the axis that hits the wall.
            let tryX = CGPoint(x: next.x, y: grenade.position.y)
            let tryY = CGPoint(x: grenade.position.x, y: next.y)
            var velocity = grenade.velocity
            if map.isInsideObstacle(tryX, padding: GrenadeConfig.radius) || !map.bounds.contains(tryX) { velocity.x = -velocity.x }
            if map.isInsideObstacle(tryY, padding: GrenadeConfig.radius) || !map.bounds.contains(tryY) { velocity.y = -velocity.y }
            grenade.velocity = velocity * GrenadeConfig.bounceDamping
            grenade.remainingDistance *= GrenadeConfig.bounceDamping
            next = grenade.position
        }
        grenade.position = next
        grenade.remainingDistance -= step
    }

    private func detonate(_ grenade: Grenade) {
        grenade.isDone = true
        let radius: CGFloat
        switch grenade.type {
        case .frag: radius = GrenadeConfig.fragRadius
        case .flash: radius = GrenadeConfig.flashRadius
        case .stun: radius = GrenadeConfig.stunRadius
        }
        let thrower = ctx.world.soldier(grenade.ownerId)
        if grenade.type == .frag {
            for vehicle in ctx.world.vehicles where vehicle.isAlive && vehicle.team != grenade.team
                && vehicle.position.distance(to: grenade.position) <= radius + vehicle.radius {
                damage.apply(GrenadeConfig.fragVehicleDamage, to: vehicle, from: thrower)
            }
        }
        for soldier in ctx.world.soldiers where soldier.isAlive && !soldier.isMounted && soldier.team != grenade.team {
            let distance = soldier.position.distance(to: grenade.position)
            guard distance <= radius, ctx.world.map.hasLineOfSight(grenade.position, soldier.position) else { continue }
            let closeness = 1 - distance / radius
            switch grenade.type {
            case .frag:
                let amount = GrenadeConfig.fragMinDamage
                    + (GrenadeConfig.fragMaxDamage - GrenadeConfig.fragMinDamage) * closeness
                damage.apply(amount, to: soldier, from: thrower, weaponName: "Frag")
            case .flash:
                let toGrenade = (grenade.position - soldier.position).angle
                let looking = abs(Angle.normalize(toGrenade - soldier.facing)) < 1.2
                let duration = GrenadeConfig.flashMaxDuration * (0.4 + 0.6 * closeness) * (looking ? 1 : 0.45)
                if duration > soldier.blindTime {
                    soldier.blindTime = duration
                    soldier.blindDuration = duration
                }
            case .stun:
                soldier.stunTime = Swift.max(soldier.stunTime, GrenadeConfig.stunDuration * (0.5 + 0.5 * closeness))
            }
        }
        ctx.bus.publish(.grenadeExploded(type: grenade.type, position: grenade.position, radius: radius))
    }
}

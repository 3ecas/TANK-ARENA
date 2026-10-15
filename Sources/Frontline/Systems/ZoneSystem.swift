import CoreGraphics

/// Smoke, shield domes, supply crates and UAV reveals.
@MainActor
final class ZoneSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func add(_ zone: AreaZone) {
        ctx.world.addZone(zone)
    }

    func update(dt: CGFloat) {
        for zone in ctx.world.zones where !zone.isDone {
            if zone.armingDelay > 0 {
                zone.armingDelay -= dt
                if zone.armingDelay <= 0 && zone.kind == .supplyCrate {
                    ctx.bus.publish(.projectileImpact(position: zone.center, kind: .grenade))
                }
                continue
            }
            zone.remaining -= dt
            if zone.remaining <= 0 || (zone.kind == .shieldDome && zone.value <= 0) {
                zone.isDone = true
                continue
            }
            if zone.kind == .supplyCrate { resupply(from: zone) }
        }
    }

    /// An active hostile dome that the segment `from -> to` enters from outside.
    func blockingDome(attackerTeam: Team, from: CGPoint, to: CGPoint) -> AreaZone? {
        for zone in ctx.world.zones where zone.kind == .shieldDome && zone.isActive && zone.value > 0 {
            guard zone.team != attackerTeam else { continue }
            if zone.contains(to) && !zone.contains(from) { return zone }
        }
        return nil
    }

    /// Units inside their own team's smoke are hidden from the other team.
    func isConcealed(_ entity: Entity, from viewer: Team) -> Bool {
        for zone in ctx.world.zones where zone.kind == .smoke && zone.isActive {
            if zone.team == entity.team && zone.team != viewer && zone.contains(entity.position) { return true }
        }
        return false
    }

    private func resupply(from zone: AreaZone) {
        let nearby = ctx.world.grid.query(center: zone.center, radius: zone.radius)
        for entity in nearby where entity.team == zone.team && entity.isAlive && !zone.usedBy.contains(entity.id) {
            zone.usedBy.insert(entity.id)
            entity.status.applyHeal(total: zone.value, duration: 4)
            if let hero = entity as? Hero {
                hero.ammo = hero.stats.magSize
                hero.reloadTimer = 0
            }
            ctx.bus.publish(.healed(targetId: entity.id, amount: zone.value, position: entity.position))
        }
    }
}

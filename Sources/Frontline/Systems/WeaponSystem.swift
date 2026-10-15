import CoreGraphics

/// Firing, reloading and switching weapons for every soldier.
@MainActor
final class WeaponSystem {
    unowned let ctx: BattleContext
    private let damage: DamageSystem

    init(ctx: BattleContext, damage: DamageSystem) {
        self.ctx = ctx
        self.damage = damage
    }

    func update(dt: CGFloat) {
        for soldier in ctx.world.soldiers where soldier.isAlive {
            soldier.timeSinceShot += dt
            soldier.switchTimer = Swift.max(0, soldier.switchTimer - dt)
            var weapon = soldier.weapons[soldier.activeIndex]
            weapon.cooldown = Swift.max(0, weapon.cooldown - dt)
            if weapon.isReloading {
                weapon.reloadTimer -= dt
                if weapon.reloadTimer <= 0 { weapon.finishReload() }
            } else if wantsShot(soldier, weapon) && soldier.switchTimer <= 0 && !soldier.isStunned {
                if weapon.magazine > 0 {
                    if weapon.cooldown <= 0 { fire(soldier, &weapon) }
                } else if weapon.hasSpareAmmo {
                    beginReload(soldier, &weapon)
                }
            }
            soldier.weapons[soldier.activeIndex] = weapon
            soldier.firePressed = false
        }
    }

    func reload(_ soldier: Soldier) {
        var weapon = soldier.weapons[soldier.activeIndex]
        guard !weapon.isReloading, weapon.magazine < weapon.def.magSize, weapon.hasSpareAmmo else { return }
        beginReload(soldier, &weapon)
        soldier.weapons[soldier.activeIndex] = weapon
    }

    /// Switches to weapon slot `index` (0 = primary, 1 = pistol). Cancels a reload in progress.
    func switchTo(_ soldier: Soldier, index: Int) {
        guard soldier.weapons.indices.contains(index), index != soldier.activeIndex else { return }
        soldier.weapons[soldier.activeIndex].reloadTimer = 0
        soldier.activeIndex = index
        soldier.switchTimer = GameConfig.weaponSwitchTime
    }

    private func wantsShot(_ soldier: Soldier, _ weapon: WeaponState) -> Bool {
        weapon.def.isAutomatic ? soldier.wantsToFire : soldier.firePressed
    }

    private func beginReload(_ soldier: Soldier, _ weapon: inout WeaponState) {
        weapon.reloadTimer = weapon.def.reloadTime
        ctx.bus.publish(.reloadStarted(soldierId: soldier.id))
    }

    private func fire(_ soldier: Soldier, _ weapon: inout WeaponState) {
        let def = weapon.def
        weapon.magazine -= 1
        weapon.cooldown = def.interval
        soldier.timeSinceShot = 0
        let moving = soldier.velocity.lengthSquared > 100
        let spread = def.spread * (moving ? GameConfig.movingSpreadMultiplier : 1) * (soldier.isBlind ? 3 : 1)
        let muzzle = soldier.position + CGPoint(angle: soldier.facing, length: soldier.radius + 8)
        for _ in 0..<def.pellets {
            let angle = soldier.facing + CGFloat.random(in: -spread...spread)
            let end = muzzle + CGPoint(angle: angle, length: def.range)
            let hit = Ballistics.trace(from: muzzle, to: end, shooter: soldier, world: ctx.world)
            ctx.bus.publish(.shotFired(shooterId: soldier.id, from: muzzle, to: hit.point, weapon: def.id,
                                       hitWall: hit.blockedByWall))
            if let victim = ctx.world.soldier(hit.soldierId) {
                let distance = muzzle.distance(to: hit.point)
                damage.apply(def.damage * falloff(distance: distance, range: def.range), to: victim, from: soldier,
                             weaponName: def.name)
            }
        }
        if weapon.magazine <= 0 && weapon.hasSpareAmmo { beginReload(soldier, &weapon) }
    }

    /// Full damage up to 60% of range, then down to 60% at max range.
    private func falloff(distance: CGFloat, range: CGFloat) -> CGFloat {
        let start = range * 0.6
        guard distance > start else { return 1 }
        return 1 - 0.4 * ((distance - start) / Swift.max(range - start, 1)).clamped(0, 1)
    }
}

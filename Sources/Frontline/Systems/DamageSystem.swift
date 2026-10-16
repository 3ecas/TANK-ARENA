import CoreGraphics

/// Applies damage to soldiers and vehicles (no friendly fire), handles deaths, kill credit and killstreak
/// rewards, and publishes events. In rush a soldier who drops is first downed (a medic can revive them).
@MainActor
final class DamageSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func apply(_ amount: CGFloat, to victim: Soldier, from attacker: Soldier?, weaponName: String) {
        // Soldiers inside a vehicle can't be hit; the vehicle takes the damage.
        guard victim.isAlive, !victim.isMounted, victim.spawnProtection <= 0, amount > 0 else { return }
        if let attacker = attacker, attacker.team == victim.team { return }
        victim.hp = Swift.max(0, victim.hp - amount)
        victim.lastAttackerId = attacker?.id
        ctx.bus.publish(.soldierHit(victimId: victim.id, attackerId: attacker?.id, damage: amount,
                                    position: victim.position))
        if victim.hp <= 0 { kill(victim, by: attacker, weaponName: weaponName) }
    }

    func apply(_ amount: CGFloat, to vehicle: Vehicle, from attacker: Soldier?) {
        guard vehicle.isAlive, amount > 0 else { return }
        if let attacker = attacker, attacker.team == vehicle.team { return }
        vehicle.hp = Swift.max(0, vehicle.hp - amount)
        vehicle.lastAttackerId = attacker?.id ?? vehicle.lastAttackerId
        ctx.bus.publish(.vehicleHit(vehicleId: vehicle.id, attackerId: attacker?.id))
    }

    private func kill(_ victim: Soldier, by attacker: Soldier?, weaponName: String) {
        victim.deaths += 1
        victim.wantsToFire = false
        victim.firePressed = false
        victim.moveDir = .zero
        victim.velocity = .zero
        victim.killStreak = 0
        victim.reward = nil
        victim.respawnTimer = victim.respawnsLeft > 0 ? BombConfig.rushRespawnDelay : 0
        if ctx.world.mode == .rush { victim.downedTime = ClassConfig.downedTime }
        if let attacker = attacker, attacker.team != victim.team {
            attacker.kills += 1
            // Vehicle kills don't feed the streak (vehicles come from kills on foot).
            if !attacker.isMounted {
                attacker.killStreak += 1
                grantReward(attacker)
            }
        }
        ctx.bus.publish(.soldierKilled(victimId: victim.id, killerId: attacker?.id, weaponName: weaponName))
    }

    /// Kills in a row earn a tank, then a helicopter (rush only).
    private func grantReward(_ soldier: Soldier) {
        guard ctx.world.mode == .rush else { return }
        var earned: VehicleKind?
        if soldier.killStreak == VehicleConfig.helicopterStreak {
            earned = .helicopter
        } else if soldier.killStreak == VehicleConfig.tankStreak && soldier.reward == nil {
            earned = .tank
        }
        guard let kind = earned else { return }
        soldier.reward = kind
        ctx.bus.publish(.rewardEarned(soldierId: soldier.id, kind: kind))
    }
}

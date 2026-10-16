import CoreGraphics

/// Applies damage (no friendly fire), handles deaths and kill credit, and publishes events.
@MainActor
final class DamageSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func apply(_ amount: CGFloat, to victim: Soldier, from attacker: Soldier?, weaponName: String) {
        guard victim.isAlive, victim.spawnProtection <= 0, amount > 0 else { return }
        if let attacker = attacker, attacker.team == victim.team { return }
        victim.hp = Swift.max(0, victim.hp - amount)
        victim.lastAttackerId = attacker?.id
        ctx.bus.publish(.soldierHit(victimId: victim.id, attackerId: attacker?.id, damage: amount,
                                    position: victim.position))
        if victim.hp <= 0 { kill(victim, by: attacker, weaponName: weaponName) }
    }

    private func kill(_ victim: Soldier, by attacker: Soldier?, weaponName: String) {
        victim.deaths += 1
        victim.wantsToFire = false
        victim.firePressed = false
        victim.moveDir = .zero
        victim.velocity = .zero
        victim.respawnTimer = victim.respawnsLeft > 0 ? BombConfig.rushRespawnDelay : 0
        if let attacker = attacker, attacker.team != victim.team { attacker.kills += 1 }
        ctx.bus.publish(.soldierKilled(victimId: victim.id, killerId: attacker?.id, weaponName: weaponName))
    }
}

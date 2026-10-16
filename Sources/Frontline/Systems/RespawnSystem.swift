import CoreGraphics

/// Brings dead soldiers back after a delay at their team's spawn, while they have respawns left
/// (bomb mode has none). In rush each attacker respawn costs a ticket; with no tickets left attackers stay down.
@MainActor
final class RespawnSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        let world = ctx.world
        // Downed soldiers wait for a medic first; the respawn countdown starts once they bleed out.
        for soldier in world.soldiers where soldier.isAwaitingRespawn && soldier.downedTime <= 0 {
            soldier.respawnTimer -= dt
            guard soldier.respawnTimer <= 0 else { continue }
            if world.mode == .rush && soldier.team == world.attackers {
                guard world.tickets > 0 else { continue }
                world.tickets -= 1
            }
            respawn(soldier)
        }
    }

    private func respawn(_ soldier: Soldier) {
        let world = ctx.world
        soldier.respawnsLeft -= 1
        soldier.position = world.randomSpawnPoint(soldier.team)
        soldier.resetLoadout(primary: soldier.weapons[0].def.id, grenade: GrenadeType.allCases.randomElement() ?? .frag)
        soldier.facing = soldier.team == world.attackers ? 0 : .pi
        soldier.aimPoint = soldier.position + CGPoint(angle: soldier.facing, length: 100)
        ctx.bus.publish(.soldierRespawned(soldierId: soldier.id))
    }
}

import CoreGraphics

/// Brings dead soldiers back after a delay at their team's current spawn (which moves as sectors fall).
/// Every attacker respawn costs a ticket; with no tickets left, attackers stay down.
@MainActor
final class RespawnSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        let world = ctx.world
        for soldier in world.soldiers where soldier.isAwaitingRespawn {
            soldier.respawnTimer -= dt
            guard soldier.respawnTimer <= 0 else { continue }
            if soldier.team == world.attackers {
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
        // Face the front: attackers look toward the enemy side (right), defenders toward the attackers (left).
        soldier.facing = soldier.team == world.attackers ? 0 : .pi
        soldier.aimPoint = soldier.position + CGPoint(angle: soldier.facing, length: 100)
        ctx.bus.publish(.soldierRespawned(soldierId: soldier.id))
    }
}

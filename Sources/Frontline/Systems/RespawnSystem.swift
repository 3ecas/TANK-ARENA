import CoreGraphics

/// Brings dead soldiers back once (after a delay) at their team's spawn.
@MainActor
final class RespawnSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        for soldier in ctx.world.soldiers where soldier.isAwaitingRespawn {
            soldier.respawnTimer -= dt
            if soldier.respawnTimer <= 0 { respawn(soldier) }
        }
    }

    private func respawn(_ soldier: Soldier) {
        soldier.respawnsLeft -= 1
        soldier.position = ctx.world.map.randomSpawnPoint(soldier.team)
        soldier.resetLoadout(primary: soldier.weapons[0].def.id, grenade: GrenadeType.allCases.randomElement() ?? .frag)
        soldier.facing = soldier.team == .blue ? 0 : .pi
        soldier.aimPoint = soldier.position + CGPoint(angle: soldier.facing, length: 100)
        ctx.bus.publish(.soldierRespawned(soldierId: soldier.id))
    }
}

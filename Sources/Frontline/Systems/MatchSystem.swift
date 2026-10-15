import CoreGraphics

/// Breakthrough flow: when the attackers hold both zones of the current sector, the front moves to the
/// next one (and they get some tickets back). Taking sector D wins the battle. Defenders win once the
/// attackers are out of tickets and nobody of theirs is left alive.
@MainActor
final class MatchSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        let world = ctx.world
        guard world.result == nil else { return }
        let active = world.activeZones
        if !active.isEmpty && active.allSatisfy({ $0.owner == world.attackers }) {
            captureSector()
            return
        }
        if world.tickets <= 0 && world.aliveCount(world.attackers) == 0 {
            finish(.victory(world.defenders))
        }
    }

    private func captureSector() {
        let world = ctx.world
        let name = world.currentSector.name
        if world.sector >= world.map.sectors.count - 1 {
            finish(.victory(world.attackers))
            return
        }
        world.sector += 1
        world.tickets += BreakthroughConfig.ticketsPerSector
        ctx.bus.publish(.sectorCaptured(name: name, attackers: world.attackers))
    }

    private func finish(_ result: MatchResult) {
        ctx.world.result = result
        ctx.bus.publish(.matchOver(winner: result.winner))
    }
}

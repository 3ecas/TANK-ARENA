import CoreGraphics

/// How a round ends.
/// Bomb mode (one life): attackers win if the bomb explodes or every defender is dead; defenders win if it is
/// defused, if every attacker dies before the plant, or if the round timer runs out with no plant.
/// Rush: destroying every station of a sector moves the fight to the next one (and refunds tickets); clearing
/// the last sector wins. Defenders win once the attackers are out of tickets and nobody of theirs is left alive.
@MainActor
final class MatchSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        guard ctx.world.result == nil else { return }
        switch ctx.world.mode {
        case .bomb: updateBomb(dt: dt)
        case .rush: updateRush()
        }
    }

    private func updateBomb(dt: CGFloat) {
        let world = ctx.world
        let bomb = world.bomb
        switch bomb.state {
        case .exploded:
            finish(.victory(world.attackers))
            return
        case .defused:
            finish(.victory(world.defenders))
            return
        default:
            break
        }
        if world.aliveCount(world.defenders) == 0 {
            finish(.victory(world.attackers))
            return
        }
        if bomb.isPlanted { return }
        if world.aliveCount(world.attackers) == 0 {
            finish(.victory(world.defenders))
            return
        }
        world.roundTimeLeft -= dt
        if world.roundTimeLeft <= 0 {
            world.roundTimeLeft = 0
            finish(.victory(world.defenders))
        }
    }

    private func updateRush() {
        let world = ctx.world
        if world.bombs.allSatisfy({ $0.isExploded }) {
            if world.isLastSector {
                finish(.victory(world.attackers))
            } else {
                let cleared = world.currentSector?.name ?? ""
                world.advanceSector()
                world.tickets += BombConfig.ticketsPerSector
                ctx.bus.publish(.sectorAdvanced(name: world.currentSector?.name ?? ""))
                ctx.bus.publish(.announcement(text: "Sector \(cleared) destroyed — on to sector \(world.currentSector?.name ?? "")!"))
            }
        } else if world.tickets <= 0 && world.aliveCount(world.attackers) == 0 && !world.anyPlanted {
            finish(.victory(world.defenders))
        }
    }

    private func finish(_ result: MatchResult) {
        ctx.world.result = result
        ctx.bus.publish(.matchOver(winner: result.winner))
    }
}

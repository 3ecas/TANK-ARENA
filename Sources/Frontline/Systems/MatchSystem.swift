import CoreGraphics

/// Bomb round rules (one life each):
/// - attackers win if the bomb explodes, or if every defender is dead;
/// - defenders win if the bomb is defused, if every attacker dies before planting,
///   or if the round timer runs out with no bomb planted.
/// Once the bomb is planted the round timer stops; killing the attackers is then not enough — it must be defused.
@MainActor
final class MatchSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        let world = ctx.world
        guard world.result == nil else { return }
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

    private func finish(_ result: MatchResult) {
        ctx.world.result = result
        ctx.bus.publish(.matchOver(winner: result.winner))
    }
}

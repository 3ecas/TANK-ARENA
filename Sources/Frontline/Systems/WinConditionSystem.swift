/// Ends the match when an HQ is destroyed.
@MainActor
final class WinConditionSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
        ctx.bus.subscribe { [unowned self] event in
            guard case .killed(let victimId, _) = event,
                  let structure = self.ctx.world.entity(victimId) as? Structure, structure.isHQ,
                  self.ctx.world.winner == nil else { return }
            let winner = structure.team.opponent
            self.ctx.world.winner = winner
            self.ctx.bus.publish(.gameOver(winner: winner))
        }
    }
}

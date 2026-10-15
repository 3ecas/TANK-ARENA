import CoreGraphics

/// Ends the battle when a team has nobody alive and nobody left to respawn.
@MainActor
final class MatchSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update() {
        let world = ctx.world
        guard world.winner == nil else { return }
        let blueLeft = world.remainingCount(.blue)
        let redLeft = world.remainingCount(.red)
        guard blueLeft == 0 || redLeft == 0 else { return }
        let winner: Team = blueLeft == 0 ? .red : .blue
        world.winner = winner
        ctx.bus.publish(.matchOver(winner: winner))
    }
}

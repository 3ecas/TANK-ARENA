import CoreGraphics

/// Match flow: 5 minutes of regular time scored by zones, then sudden death on a tie.
/// A team with nobody alive and nobody left to respawn loses; if both are wiped out at once it is a draw.
@MainActor
final class MatchSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        let world = ctx.world
        guard world.result == nil else { return }
        let blueLeft = world.remainingCount(.blue)
        let redLeft = world.remainingCount(.red)
        if blueLeft == 0 && redLeft == 0 {
            finish(.draw)
            return
        }
        if blueLeft == 0 { finish(.victory(.red)); return }
        if redLeft == 0 { finish(.victory(.blue)); return }

        guard !world.suddenDeath else { return }
        world.timeRemaining -= dt
        guard world.timeRemaining <= 0 else { return }
        world.timeRemaining = 0
        let blue = world.score(.blue), red = world.score(.red)
        if blue > red {
            finish(.victory(.blue))
        } else if red > blue {
            finish(.victory(.red))
        } else {
            startSuddenDeath()
        }
    }

    /// Tie on points: no more respawns, fight until one team is wiped out.
    private func startSuddenDeath() {
        let world = ctx.world
        world.suddenDeath = true
        for soldier in world.soldiers { soldier.respawnsLeft = 0 }
        ctx.bus.publish(.suddenDeath)
        ctx.bus.publish(.announcement(text: "SUDDEN DEATH — no more respawns!"))
    }

    private func finish(_ result: MatchResult) {
        ctx.world.result = result
        ctx.bus.publish(.matchOver(winner: result.winner))
    }
}

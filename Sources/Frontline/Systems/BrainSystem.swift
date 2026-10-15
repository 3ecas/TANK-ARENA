import CoreGraphics

/// Runs the AI brain of every non-hero unit (troops, structures, camps, summons).
@MainActor
final class BrainSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        for entity in ctx.world.entities where entity.isAlive && !entity.isRemoved {
            entity.brain?.update(entity, ctx: ctx, dt: dt)
        }
    }
}

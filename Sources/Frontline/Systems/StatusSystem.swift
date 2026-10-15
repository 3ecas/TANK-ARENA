import CoreGraphics

/// Ticks blindness, stun and spawn protection.
@MainActor
final class StatusSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        for soldier in ctx.world.soldiers where soldier.isAlive {
            soldier.blindTime = Swift.max(0, soldier.blindTime - dt)
            soldier.stunTime = Swift.max(0, soldier.stunTime - dt)
            soldier.spawnProtection = Swift.max(0, soldier.spawnProtection - dt)
        }
    }
}

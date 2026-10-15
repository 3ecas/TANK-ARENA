import CoreGraphics

/// Channeled teleport back to base. Interrupted by damage, moving, dashing or shooting.
@MainActor
final class RecallSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
        ctx.bus.subscribe { [unowned self] event in
            if case .damaged(let targetId, _, _, _) = event, let hero = self.ctx.world.hero(targetId) {
                self.cancel(hero)
            }
        }
    }

    @discardableResult
    func begin(_ hero: Hero) -> Bool {
        guard hero.isAlive, !hero.isRecalling, !ctx.world.map.isInBase(hero.position, team: hero.team) else {
            return false
        }
        hero.recallTimer = GameConfig.recallTime
        hero.targetId = nil
        ctx.bus.publish(.recallStarted(heroId: hero.id))
        return true
    }

    func cancel(_ hero: Hero) {
        guard hero.isRecalling else { return }
        hero.recallTimer = nil
        ctx.bus.publish(.recallCancelled(heroId: hero.id))
    }

    func update(dt: CGFloat) {
        for hero in ctx.world.heroes where hero.isRecalling {
            guard hero.isAlive else { hero.recallTimer = nil; continue }
            if hero.moveDir.lengthSquared > 0.01 || hero.status.isDashing {
                cancel(hero)
                continue
            }
            let remaining = (hero.recallTimer ?? 0) - dt
            if remaining <= 0 {
                hero.recallTimer = nil
                hero.position = hero.spawnPoint
                hero.targetId = nil
                ctx.bus.publish(.recallCompleted(heroId: hero.id))
            } else {
                hero.recallTimer = remaining
            }
        }
    }
}

import CoreGraphics

/// League-style hero movement: walk along a nav-grid path to the move goal, or chase the
/// attack target until it is in weapon range. Writes `moveDir`; MovementSystem integrates it.
@MainActor
final class HeroMovementSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        let world = ctx.world
        for hero in world.heroes {
            hero.dodgeCooldown = Swift.max(0, hero.dodgeCooldown - dt)
            guard hero.isAlive else {
                hero.moveGoal = nil
                hero.moveDir = .zero
                continue
            }
            var goal = hero.moveGoal
            if hero.chasesTarget, let target = world.entity(hero.targetId), ctx.targeting.canTarget(hero, target) {
                let inRange = ctx.targeting.inRange(hero, target, range: hero.stats.range * 0.95)
                goal = inRange ? nil : target.position
            }
            guard let destination = goal else {
                hero.moveDir = .zero
                hero.navigator.clear()
                continue
            }
            if let direction = hero.navigator.direction(from: hero.position, to: destination, nav: world.nav, dt: dt) {
                hero.moveDir = direction
            } else {
                hero.moveDir = .zero
                if hero.moveGoal != nil && !hero.chasesTarget { hero.moveGoal = nil }
            }
        }
    }
}

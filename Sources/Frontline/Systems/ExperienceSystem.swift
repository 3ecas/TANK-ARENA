import CoreGraphics

/// XP, levels (1-18) and ability points.
@MainActor
final class ExperienceSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func grantXP(_ hero: Hero, _ amount: CGFloat) {
        guard hero.level < HeroConfig.maxLevel, amount > 0 else { return }
        hero.xp += amount
        while hero.level < HeroConfig.maxLevel && hero.xp >= hero.xpToNextLevel {
            hero.xp -= hero.xpToNextLevel
            hero.level += 1
            hero.abilityPoints += 1
            StatCalculator.apply(to: hero)
            ctx.bus.publish(.levelUp(heroId: hero.id, level: hero.level))
        }
        if hero.level >= HeroConfig.maxLevel { hero.xp = 0 }
    }
}

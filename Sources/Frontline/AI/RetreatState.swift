import CoreGraphics

/// Low HP: run home, recall once nobody is chasing.
@MainActor
final class RetreatState: HeroAIState {
    func enter(_ ai: HeroAIController) {
        ai.hero.targetId = nil
    }

    func think(_ ai: HeroAIController) -> HeroAIStateKind? {
        let hero = ai.hero
        if ai.isInBase { return .shopping }
        if ai.perception.enemiesNear(750) == 0 && ai.stateTime > 1 { return .recalling }
        // Keep shooting the closest threat while backing off (hard AI only).
        if ai.ctx.difficulty == .hard, let enemy = ai.perception.nearestEnemyHero,
           enemy.position.distance(to: hero.position) <= hero.stats.range {
            hero.targetId = enemy.id
        } else {
            hero.targetId = nil
        }
        ai.moveGoal = hero.spawnPoint
        return nil
    }
}

import CoreGraphics

/// Default behaviour: hold the lane, last-hit troops, poke heroes, push or defend structures.
/// Also decides when to trade, gank, take objectives or go back to shop.
@MainActor
final class LaningState: HeroAIState {
    func enter(_ ai: HeroAIController) {}

    func think(_ ai: HeroAIController) -> HeroAIStateKind? {
        if let next = transition(ai) { return next }
        let hero = ai.hero
        let target = chooseTarget(ai)
        hero.targetId = target?.id
        if let target = target {
            ai.moveGoal = ai.safePoint(ai.attackPosition(for: target))
        } else {
            ai.moveGoal = ai.safePoint(ai.perception.laneFront(ai.lane))
        }
        return nil
    }

    private func transition(_ ai: HeroAIController) -> HeroAIStateKind? {
        let world = ai.world
        if AITactics.tradeOpportunity(ai) != nil { return .trading }
        let gankInterval = ai.entry.role == .roamer ? 25 : ai.tuning.gankInterval
        if world.time - ai.lastGankTime > gankInterval {
            ai.lastGankTime = world.time
            if let target = AITactics.gankTarget(ai) {
                ai.gankTargetId = target.id
                return .ganking
            }
        }
        if let goal = AITactics.objectiveGoal(ai) {
            ai.objective = goal
            return .objective
        }
        let quiet = ai.perception.enemiesNear(900) == 0
        if quiet && ai.stateTime > 15 && ai.shopper.wantsToShop() { return .recalling }
        return nil
    }

    private func chooseTarget(_ ai: HeroAIController) -> Entity? {
        let hero = ai.hero
        let p = ai.perception
        let reach = hero.stats.range * 1.25
        let candidates = p.enemyUnits.filter { unit in
            unit.position.distance(to: hero.position) <= reach
                && (p.dangerousStructure(at: unit.position).map { p.isTanked($0) } ?? true)
        }
        // Last hits first, then the weakest unit.
        if let lastHit = candidates.first(where: { $0.hp <= hero.stats.damage * 1.3 }) { return lastHit }
        if let weakest = candidates.min(by: { $0.hp < $1.hp }) { return weakest }
        // Push: hit a structure that our troops are tanking.
        if let structure = p.enemyStructures.first(where: { !$0.isInvulnerable && p.isTanked($0) }) {
            return structure
        }
        // Poke an enemy hero that is not under its tower.
        if let enemy = p.nearestEnemyHero, enemy.position.distance(to: hero.position) <= hero.stats.range,
           p.dangerousStructure(at: enemy.position) == nil {
            return enemy
        }
        return nil
    }
}

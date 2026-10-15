import CoreGraphics

/// Roam to another lane and attack a vulnerable enemy hero.
@MainActor
final class GankState: HeroAIState {
    func enter(_ ai: HeroAIController) {
        ai.lastGankTime = ai.world.time
    }

    func think(_ ai: HeroAIController) -> HeroAIStateKind? {
        let hero = ai.hero
        guard ai.stateTime < AIConfig.gankDuration,
              let target = ai.world.hero(ai.gankTargetId), target.isAlive else { return .laning }
        if let tower = ai.perception.dangerousStructure(at: hero.position), !ai.perception.isTanked(tower) {
            return .laning
        }
        if ai.canAttack(target) {
            hero.targetId = target.id
            ai.moveGoal = ai.attackPosition(for: target, rangeFactor: 0.7)
        } else {
            hero.targetId = nil
            ai.moveGoal = ai.safePoint(target.position)
        }
        return nil
    }
}

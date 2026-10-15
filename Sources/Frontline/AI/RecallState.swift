import CoreGraphics

/// Channel the recall to base (to heal or to shop).
@MainActor
final class RecallState: HeroAIState {
    func enter(_ ai: HeroAIController) {
        ai.moveGoal = nil
        ai.hero.targetId = nil
        ai.ctx.recall.begin(ai.hero)
    }

    func think(_ ai: HeroAIController) -> HeroAIStateKind? {
        if ai.isInBase { return .shopping }
        if !ai.hero.isRecalling {
            return ai.hero.hpFraction < ai.tuning.retreatHp + 0.15 ? .retreating : .laning
        }
        ai.moveGoal = nil
        return nil
    }
}

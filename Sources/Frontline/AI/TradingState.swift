import CoreGraphics

/// Fight an enemy hero at weapon range while it is favourable.
@MainActor
final class TradingState: HeroAIState {
    private var targetId: Int?

    func enter(_ ai: HeroAIController) {
        targetId = AITactics.tradeOpportunity(ai)?.id
    }

    func think(_ ai: HeroAIController) -> HeroAIStateKind? {
        let hero = ai.hero
        guard ai.stateTime < AIConfig.tradeDuration,
              let target = ai.world.hero(targetId), target.isAlive, ai.canAttack(target) else { return .laning }
        // Bail out if the fight turned against us or the target ran under its tower.
        if hero.hpFraction + 0.2 < target.hpFraction { return .laning }
        if let tower = ai.perception.dangerousStructure(at: target.position), !ai.perception.isTanked(tower) {
            let dive = ai.ctx.difficulty == .hard && target.hpFraction < 0.2
            if !dive { return .laning }
        }
        hero.targetId = target.id
        let strafe = CGPoint(angle: (target.position - hero.position).angle + .pi / 2,
                             length: CGFloat.random(in: -60...60))
        ai.moveGoal = ai.attackPosition(for: target, rangeFactor: 0.8) + strafe
        return nil
    }
}

import CoreGraphics

/// An objective the AI decided to go for.
enum AIObjectiveGoal {
    case capture(CapturePointKind, CGPoint)
    case camp(CGPoint)

    var position: CGPoint {
        switch self {
        case .capture(_, let p), .camp(let p): return p
        }
    }
}

/// Capture a point, clear a mercenary camp or fight the depot guardian.
@MainActor
final class ObjectiveState: HeroAIState {
    func enter(_ ai: HeroAIController) {}

    func think(_ ai: HeroAIController) -> HeroAIStateKind? {
        guard let goal = ai.objective, ai.stateTime < AIConfig.objectiveDuration else { return .laning }
        let hero = ai.hero
        if AITactics.tradeOpportunity(ai) != nil { return .trading }

        switch goal {
        case .capture(let kind, let position):
            if ai.world.capturePoint(kind)?.owner == hero.team { return .laning }
            let enemy = ai.perception.enemyHeroes.first { ai.canAttack($0) }
            hero.targetId = enemy?.id ?? ai.perception.enemyUnits.first?.id
            let jitter = CGPoint(x: CGFloat.random(in: -60...60), y: CGFloat.random(in: -60...60))
            ai.moveGoal = position + jitter
        case .camp(let position):
            let monsters = ai.perception.neutrals.filter { $0.position.distance(to: position) < 600 }
            guard let monster = monsters.min(by: { $0.hp < $1.hp }) else {
                return hero.position.distance(to: position) < 300 ? .laning : moveTo(ai, position)
            }
            hero.targetId = monster.id
            ai.moveGoal = ai.attackPosition(for: monster, rangeFactor: 0.8)
        }
        return nil
    }

    private func moveTo(_ ai: HeroAIController, _ position: CGPoint) -> HeroAIStateKind? {
        ai.hero.targetId = nil
        ai.moveGoal = position
        return nil
    }
}

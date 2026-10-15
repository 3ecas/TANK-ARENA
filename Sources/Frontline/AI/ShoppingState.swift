import CoreGraphics

/// At base: buy items, fix the loadout and heal up before heading out.
@MainActor
final class ShoppingState: HeroAIState {
    func enter(_ ai: HeroAIController) {
        ai.hero.targetId = nil
        ai.shopper.shop()
    }

    func think(_ ai: HeroAIController) -> HeroAIStateKind? {
        guard ai.isInBase else { return .laning }
        ai.shopper.shop()
        ai.hero.targetId = nil
        ai.moveGoal = nil
        return ai.hero.hpFraction >= 0.95 ? .laning : nil
    }
}

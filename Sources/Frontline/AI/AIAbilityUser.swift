import CoreGraphics

/// Decides when an AI hero uses its abilities: rate-limited by difficulty and
/// driven by simple rules (clusters for call-ins, low HP for heals, fights for buffs).
@MainActor
final class AIAbilityUser {
    let hero: Hero
    unowned let ctx: GameContext
    private var lastCastTime: CGFloat = -100

    init(hero: Hero, ctx: GameContext) {
        self.hero = hero
        self.ctx = ctx
    }

    func consider(state: HeroAIStateKind, goal: CGPoint?) {
        let tuning = ctx.tuning
        guard ctx.world.time - lastCastTime >= tuning.minCastGap,
              CGFloat.random(in: 0...1) < tuning.abilityChance else { return }
        for slot in (0..<Loadout.slotCount).shuffled() {
            guard ctx.abilities.readiness(hero, slot: slot) == .success,
                  let id = hero.loadout.ability(inSlot: slot),
                  let target = AIAbilityRules.target(for: id, hero: hero, state: state, goal: goal, ctx: ctx)
            else { continue }
            let def = AbilityCatalog.def(id)
            let error = def.castMode.isInstant ? CGPoint.zero
                : CGPoint(x: CGFloat.random(in: -1...1), y: CGFloat.random(in: -1...1)) * tuning.aimError
            if ctx.abilities.tryCast(hero, slot: slot, target: target + error) == .success {
                lastCastTime = ctx.world.time
                return
            }
        }
    }
}

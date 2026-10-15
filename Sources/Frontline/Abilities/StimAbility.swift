import CoreGraphics

/// Trades a little HP for a burst of fire rate and speed.
@MainActor
struct StimAbility: Ability {
    let id = AbilityID.stim

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        let hero = cast.caster
        hero.hp = Swift.max(1, hero.hp - GameConfig.stimHpCost)
        hero.status.applyFireRateBoost(cast.value, duration: cast.duration)
        hero.status.applySpeedBoost(StrikeConfig.stimSpeedBoost, duration: cast.duration)
        return true
    }
}

import CoreGraphics

/// Short dash toward the cursor. Also shakes off slows.
@MainActor
struct CombatRollAbility: Ability {
    let id = AbilityID.combatRoll

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        let hero = cast.caster
        let speed = cast.value / GameConfig.dashDuration
        hero.status.slowTime = 0
        hero.status.applyDash(velocity: cast.direction * speed, duration: GameConfig.dashDuration)
        return true
    }
}

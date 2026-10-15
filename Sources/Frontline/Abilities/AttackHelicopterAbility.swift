import CoreGraphics

/// Ultimate: a temporary gunship escorts the caster.
struct AttackHelicopterAbility: Ability {
    let id = AbilityID.attackHelicopter

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        guard ctx.summons.canSummon(.helicopter, owner: cast.caster) else { return false }
        ctx.summons.spawnHelicopter(owner: cast.caster, power: cast.value, lifetime: cast.duration)
        return true
    }
}

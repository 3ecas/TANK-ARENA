import CoreGraphics

/// A squad of soldiers that escorts the caster.
@MainActor
struct ReinforcementsAbility: Ability {
    let id = AbilityID.reinforcements

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        guard ctx.summons.canSummon(.squad, owner: cast.caster) else { return false }
        ctx.summons.spawnSquad(owner: cast.caster, at: cast.target, size: Int(cast.value), lifetime: cast.duration)
        return true
    }
}

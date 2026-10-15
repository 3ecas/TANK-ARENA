import CoreGraphics

/// Ultimate: an AI tank is dropped in and pushes the nearest lane.
struct CallTankAbility: Ability {
    let id = AbilityID.callTank

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        guard ctx.summons.canSummon(.tank, owner: cast.caster) else { return false }
        ctx.summons.spawnTank(owner: cast.caster, at: cast.target, power: cast.value, lifetime: cast.duration)
        return true
    }
}

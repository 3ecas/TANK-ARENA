import CoreGraphics

/// Deploys an automated turret (limited number active).
@MainActor
struct SentryTurretAbility: Ability {
    let id = AbilityID.sentryTurret

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        guard ctx.summons.canSummon(.sentry, owner: cast.caster) else { return false }
        ctx.summons.spawnSentry(owner: cast.caster, at: cast.target, power: cast.value, lifetime: cast.duration)
        return true
    }
}

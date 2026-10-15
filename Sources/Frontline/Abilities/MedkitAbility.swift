import CoreGraphics

/// Heal over time for the caster; nearby allies receive a share.
@MainActor
struct MedkitAbility: Ability {
    let id = AbilityID.medkit

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        let hero = cast.caster
        let total = cast.scaledValue
        hero.status.applyHeal(total: total, duration: cast.duration)
        ctx.bus.publish(.healed(targetId: hero.id, amount: total, position: hero.position))
        let allies = ctx.targeting.allies(of: hero.team, near: hero.position, radius: cast.def.radius)
        for ally in allies where ally !== hero && ally.isAlive && !(ally is Structure) {
            ally.status.applyHeal(total: total * StrikeConfig.medkitAllyShare, duration: cast.duration)
        }
        return true
    }
}

import CoreGraphics

/// Electromagnetic pulse: disables vehicles and turrets, slows soldiers.
@MainActor
struct EMPStrikeAbility: Ability {
    let id = AbilityID.empStrike

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        let hero = cast.caster
        let timing = StrikeConfig.emp
        ctx.strikes.schedule(StrikeZone(
            id: ctx.world.makeId(), team: hero.team, ownerId: hero.id, kind: .emp,
            shape: .circle(center: cast.target, radius: cast.def.radius), direction: cast.direction,
            warning: timing.warning, impactCount: timing.impacts, impactInterval: timing.interval,
            damagePerImpact: cast.scaledValue, impactRadius: cast.def.radius, effectDuration: cast.duration))
        return true
    }
}

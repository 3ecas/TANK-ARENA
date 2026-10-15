import CoreGraphics

/// Ultimate: bombers saturate a huge circle.
struct CarpetBombingAbility: Ability {
    let id = AbilityID.carpetBombing

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        let hero = cast.caster
        let timing = StrikeConfig.carpet
        ctx.strikes.schedule(StrikeZone(
            id: ctx.world.makeId(), team: hero.team, ownerId: hero.id, kind: .carpet,
            shape: .circle(center: cast.target, radius: cast.def.radius), direction: cast.direction,
            warning: timing.warning, impactCount: timing.impacts, impactInterval: timing.interval,
            damagePerImpact: cast.scaledValue, impactRadius: timing.impactRadius))
        return true
    }
}

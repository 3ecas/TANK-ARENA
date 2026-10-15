import CoreGraphics

/// Delayed barrage of shells landing randomly inside a circle.
struct ArtilleryBarrageAbility: Ability {
    let id = AbilityID.artilleryBarrage

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        let hero = cast.caster
        let timing = StrikeConfig.artillery
        ctx.strikes.schedule(StrikeZone(
            id: ctx.world.makeId(), team: hero.team, ownerId: hero.id, kind: .artillery,
            shape: .circle(center: cast.target, radius: cast.def.radius), direction: cast.direction,
            warning: timing.warning, impactCount: timing.impacts, impactInterval: timing.interval,
            damagePerImpact: cast.scaledValue, impactRadius: timing.impactRadius))
        return true
    }
}

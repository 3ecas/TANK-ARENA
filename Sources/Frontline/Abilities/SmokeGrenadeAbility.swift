import CoreGraphics

/// Smoke cloud: friendly units inside are hidden from the enemy team.
struct SmokeGrenadeAbility: Ability {
    let id = AbilityID.smokeGrenade

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        ctx.zones.add(AreaZone(id: ctx.world.makeId(), team: cast.caster.team, kind: .smoke, center: cast.target,
                               radius: cast.def.radius, duration: cast.duration))
        return true
    }
}

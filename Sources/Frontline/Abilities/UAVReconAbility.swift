import CoreGraphics

/// Reveals a large area of the fog of war for a few seconds.
struct UAVReconAbility: Ability {
    let id = AbilityID.uavRecon

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        ctx.zones.add(AreaZone(id: ctx.world.makeId(), team: cast.caster.team, kind: .uavReveal,
                               center: cast.target, radius: cast.value, duration: cast.duration))
        ctx.vision.recompute()
        return true
    }
}

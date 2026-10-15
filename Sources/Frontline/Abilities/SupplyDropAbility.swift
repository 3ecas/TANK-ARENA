import CoreGraphics

/// A crate parachutes in after a short delay; allies touching it heal and refill ammo.
struct SupplyDropAbility: Ability {
    let id = AbilityID.supplyDrop

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        ctx.zones.add(AreaZone(id: ctx.world.makeId(), team: cast.caster.team, kind: .supplyCrate,
                               center: cast.target, radius: cast.def.radius, duration: cast.duration,
                               value: cast.scaledValue, armingDelay: GameConfig.supplyDropDelay))
        return true
    }
}

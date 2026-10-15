import CoreGraphics

/// Throws a grenade that explodes where it lands.
struct FragGrenadeAbility: Ability {
    let id = AbilityID.fragGrenade

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        let hero = cast.caster
        let grenade = Projectile(
            id: ctx.world.makeId(), team: hero.team, sourceId: hero.id, kind: .grenade,
            from: hero.position, targetId: nil, targetPoint: cast.target, speed: StrikeConfig.grenadeSpeed,
            damage: cast.scaledValue, splashRadius: cast.def.radius, vsArmored: 1)
        ctx.world.addProjectile(grenade)
        return true
    }
}

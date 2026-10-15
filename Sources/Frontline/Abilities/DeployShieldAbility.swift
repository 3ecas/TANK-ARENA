import CoreGraphics

/// Drops a dome in front of the soldier that blocks enemy fire coming from outside.
struct DeployShieldAbility: Ability {
    let id = AbilityID.deployShield

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        let hero = cast.caster
        let center = hero.position + cast.direction * StrikeConfig.shieldOffset
        ctx.zones.add(AreaZone(id: ctx.world.makeId(), team: hero.team, kind: .shieldDome, center: center,
                               radius: cast.def.radius, duration: cast.duration, value: cast.scaledValue))
        return true
    }
}

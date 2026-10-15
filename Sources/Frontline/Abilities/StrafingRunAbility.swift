import CoreGraphics

/// A jet strafes a line through the target after a telegraphed warning.
struct StrafingRunAbility: Ability {
    let id = AbilityID.strafingRun

    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool {
        guard case .line(let length) = cast.def.castMode else { return false }
        let hero = cast.caster
        let line = AbilityGeometry.strafeLine(caster: hero.position, target: cast.target, length: length,
                                              fallbackAngle: hero.bodyAngle)
        let timing = StrikeConfig.strafing
        ctx.strikes.schedule(StrikeZone(
            id: ctx.world.makeId(), team: hero.team, ownerId: hero.id, kind: .strafing,
            shape: .line(from: line.from, to: line.to, width: cast.def.radius * 2), direction: cast.direction,
            warning: timing.warning, impactCount: timing.impacts, impactInterval: timing.interval,
            damagePerImpact: cast.scaledValue, impactRadius: timing.impactRadius))
        return true
    }
}

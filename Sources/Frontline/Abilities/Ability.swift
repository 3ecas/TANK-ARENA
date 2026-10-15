import CoreGraphics

/// Everything an ability needs to know about one cast.
@MainActor
struct AbilityCast {
    let caster: Hero
    /// Cursor position, already clamped to the ability range.
    let target: CGPoint
    let rank: Int
    let def: AbilityDef

    var value: CGFloat { def.value(at: rank) }
    var duration: CGFloat { def.duration(at: rank) }
    /// Ability value scaled by the caster's ability power.
    var scaledValue: CGFloat { value * caster.stats.abilityPower }
    var direction: CGPoint {
        AbilityGeometry.direction(from: caster.position, to: target, fallbackAngle: caster.bodyAngle)
    }
}

/// One purchasable ability. Returns false when the cast could not happen (no cooldown is spent).
@MainActor
protocol Ability {
    var id: AbilityID { get }
    func cast(_ cast: AbilityCast, ctx: GameContext) -> Bool
}

import CoreGraphics

/// Shared geometry so casting and the aiming reticle always agree.
enum AbilityGeometry {
    static func direction(from origin: CGPoint, to target: CGPoint, fallbackAngle: CGFloat) -> CGPoint {
        let delta = target - origin
        return delta.lengthSquared > 1 ? delta.normalized : CGPoint(angle: fallbackAngle)
    }

    /// Strafing line centred on the target, oriented from the caster toward the target.
    static func strafeLine(caster: CGPoint, target: CGPoint, length: CGFloat,
                           fallbackAngle: CGFloat) -> (from: CGPoint, to: CGPoint) {
        let dir = direction(from: caster, to: target, fallbackAngle: fallbackAngle)
        return (target - dir * (length / 2), target + dir * (length / 2))
    }

    /// Where an ability will actually land for a given cursor position.
    static func clampedTarget(_ def: AbilityDef, caster: CGPoint, cursor: CGPoint) -> CGPoint {
        def.range > 0 ? cursor.limited(from: caster, maxDistance: def.range) : cursor
    }
}

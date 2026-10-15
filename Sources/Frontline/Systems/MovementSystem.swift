import CoreGraphics

/// Integrates movement from `moveDir`, speed modifiers, dashes and stuns.
@MainActor
final class MovementSystem {
    unowned let ctx: GameContext
    private let turnRate: CGFloat = 5

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        let bounds = ctx.world.map.bounds.insetBy(dx: 24, dy: 24)
        for entity in ctx.world.entities where entity.isAlive && !entity.isStatic {
            let velocity: CGPoint
            if entity.status.isDashing {
                velocity = entity.status.dashVelocity
            } else if entity.status.isStunned {
                velocity = .zero
            } else {
                velocity = entity.moveDir.clampedLength(1) * (entity.baseSpeed * entity.status.speedMultiplier)
            }
            entity.velocity = velocity
            guard velocity.lengthSquared > 1 else { continue }
            entity.position = (entity.position + velocity * dt).clamped(to: bounds)
            if !(entity is Hero) {
                let rate = entity.kind.isVehicle ? turnRate * 0.6 : turnRate * 2
                entity.bodyAngle = Angle.approach(entity.bodyAngle, velocity.angle, maxStep: rate * dt)
            }
        }
    }
}

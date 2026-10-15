import CoreGraphics

/// Keeps ground units out of structures and gently separates overlapping units.
@MainActor
final class CollisionSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func update() {
        let world = ctx.world
        for entity in world.entities where entity.isAlive && !entity.isStatic && !entity.isFlying {
            for structure in world.structures where structure.isAlive {
                push(entity, outOf: structure.position, minDistance: structure.radius + entity.radius, strength: 1)
            }
            let neighbours = world.grid.query(center: entity.position, radius: entity.radius + 24)
            for other in neighbours where other !== entity && !other.isFlying && !other.isStatic {
                push(entity, outOf: other.position, minDistance: entity.radius + other.radius, strength: 0.5)
            }
        }
    }

    private func push(_ entity: Entity, outOf center: CGPoint, minDistance: CGFloat, strength: CGFloat) {
        let delta = entity.position - center
        let distSq = delta.lengthSquared
        guard distSq < minDistance * minDistance else { return }
        let dist = distSq.squareRoot()
        let normal = dist > 0.01 ? delta / dist : CGPoint(angle: CGFloat(entity.id % 628) / 100)
        entity.position += normal * ((minDistance - dist) * strength)
    }
}

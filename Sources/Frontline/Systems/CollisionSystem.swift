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
            for building in world.city.buildings(near: entity.position, radius: entity.radius + 4) {
                push(entity, outOf: building.rect)
            }
            for structure in world.structures where structure.isAlive {
                push(entity, outOf: structure.position, minDistance: structure.radius + entity.radius, strength: 1)
            }
            let neighbours = world.grid.query(center: entity.position, radius: entity.radius + 24)
            for other in neighbours where other !== entity && !other.isFlying && !other.isStatic {
                push(entity, outOf: other.position, minDistance: entity.radius + other.radius, strength: 0.5)
            }
        }
    }

    /// Pushes a circle out of an axis-aligned building footprint.
    private func push(_ entity: Entity, outOf rect: CGRect) {
        let p = entity.position
        let r = entity.radius
        if rect.contains(p) {
            let left = p.x - rect.minX, right = rect.maxX - p.x
            let bottom = p.y - rect.minY, top = rect.maxY - p.y
            let smallest = Swift.min(left, right, bottom, top)
            if smallest == left { entity.position.x = rect.minX - r }
            else if smallest == right { entity.position.x = rect.maxX + r }
            else if smallest == bottom { entity.position.y = rect.minY - r }
            else { entity.position.y = rect.maxY + r }
            return
        }
        let closest = CGPoint(x: p.x.clamped(rect.minX, rect.maxX), y: p.y.clamped(rect.minY, rect.maxY))
        let delta = p - closest
        let distance = delta.length
        if distance < r && distance > 0.001 {
            entity.position = closest + delta * (r / distance)
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

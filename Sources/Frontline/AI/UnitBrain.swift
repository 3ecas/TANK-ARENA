import CoreGraphics

/// Per-unit decision maker. Brains only write intent (`moveDir`, `targetId`); systems act on it.
@MainActor
protocol UnitBrain: AnyObject {
    func update(_ entity: Entity, ctx: GameContext, dt: CGFloat)
}

@MainActor
enum BrainHelpers {
    /// Steers `entity` toward `point`, sliding around structures.
    static func move(_ entity: Entity, toward point: CGPoint, ctx: GameContext, stopDistance: CGFloat = 8) {
        if entity.position.distance(to: point) <= stopDistance {
            entity.moveDir = .zero
            return
        }
        entity.moveDir = entity.isFlying
            ? (point - entity.position).normalized
            : Steering.direction(from: entity.position, to: point, radius: entity.radius,
                                 obstacles: ctx.world.structures)
    }

    /// Chases `target` until it is in weapon range, then holds position.
    static func engage(_ entity: Entity, target: Entity, ctx: GameContext) {
        let range = entity.attack?.range ?? 0
        if ctx.targeting.inRange(entity, target, range: range * 0.92) {
            entity.moveDir = .zero
        } else {
            move(entity, toward: target.position, ctx: ctx)
        }
    }
}

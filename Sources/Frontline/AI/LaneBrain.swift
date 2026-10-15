import CoreGraphics

/// Lane troops (and pushing summons): walk the lane, fight whatever hostile they meet.
@MainActor
final class LaneBrain: UnitBrain {
    let path: LanePath
    private(set) var waypointIndex: Int
    private let aggroRange: CGFloat
    private var retargetTimer: CGFloat = 0

    init(path: LanePath, startIndex: Int, aggroRange: CGFloat = WaveConfig.troopAggroRange) {
        self.path = path
        self.waypointIndex = Swift.min(Swift.max(startIndex, 0), path.points.count - 1)
        self.aggroRange = aggroRange
    }

    func update(_ entity: Entity, ctx: GameContext, dt: CGFloat) {
        retargetTimer -= dt
        let range = entity.attack?.range ?? 0
        let current = ctx.world.entity(entity.targetId)
        var keep = false
        if let current = current, ctx.targeting.canTarget(entity, current),
           current.position.distance(to: entity.position) <= aggroRange + current.radius + 60 {
            // Keep a target we can already shoot; otherwise look for something closer now and then.
            keep = ctx.targeting.inRange(entity, current, range: range) || retargetTimer > 0
        }
        if !keep {
            retargetTimer = 0.35
            let searchRadius = Swift.max(aggroRange, range + 40)
            entity.targetId = ctx.targeting.nearestTarget(for: entity, within: searchRadius, includeNeutral: false)?.id
        }

        if let target = ctx.world.entity(entity.targetId), entity.attack != nil {
            BrainHelpers.engage(entity, target: target, ctx: ctx)
            return
        }
        followPath(entity, ctx: ctx)
    }

    private func followPath(_ entity: Entity, ctx: GameContext) {
        let waypoint = path.points[waypointIndex]
        if entity.position.distance(to: waypoint) < 60 && waypointIndex < path.points.count - 1 {
            waypointIndex += 1
        }
        BrainHelpers.move(entity, toward: path.points[waypointIndex], ctx: ctx, stopDistance: 30)
    }
}

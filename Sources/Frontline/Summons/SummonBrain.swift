import CoreGraphics

/// Squads and helicopters: escort the owner and fight around them.
/// When the owner dies or is far away, control is handed off to lane AI.
@MainActor
final class SummonBrain: UnitBrain {
    let ownerId: Int
    private let slot: Int
    private let slotCount: Int
    private var retargetTimer: CGFloat = 0

    init(ownerId: Int, slot: Int, slotCount: Int) {
        self.ownerId = ownerId
        self.slot = slot
        self.slotCount = slotCount
    }

    func update(_ entity: Entity, ctx: GameContext, dt: CGFloat) {
        guard let owner = ctx.world.hero(ownerId), owner.isAlive,
              owner.position.distance(to: entity.position) < SummonConfig.leashDistance else {
            handOff(entity, ctx: ctx)
            return
        }
        retargetTimer -= dt
        chooseTarget(entity, owner: owner, ctx: ctx)

        if let target = ctx.world.entity(entity.targetId), entity.attack != nil {
            BrainHelpers.engage(entity, target: target, ctx: ctx)
            return
        }
        let spread = (CGFloat(slot) - CGFloat(slotCount - 1) / 2) * 0.6
        let angle = owner.bodyAngle + .pi + spread
        let spot = owner.position + CGPoint(angle: angle, length: SummonConfig.followDistance)
        BrainHelpers.move(entity, toward: spot, ctx: ctx, stopDistance: 20)
    }

    private func chooseTarget(_ entity: Entity, owner: Hero, ctx: GameContext) {
        // Focus the owner's target when it is close enough.
        if let ownerTarget = ctx.world.entity(owner.targetId), ctx.targeting.canTarget(entity, ownerTarget),
           ownerTarget.position.distance(to: owner.position) < SummonConfig.engageRadius + 200 {
            entity.targetId = ownerTarget.id
            return
        }
        let current = ctx.world.entity(entity.targetId)
        let currentValid = current.map { ctx.targeting.canTarget(entity, $0) } ?? false
        if !currentValid || retargetTimer <= 0 {
            retargetTimer = 0.4
            entity.targetId = ctx.targeting.nearestTarget(for: entity, within: SummonConfig.engageRadius,
                                                          includeNeutral: false, around: owner.position)?.id
        }
    }

    private func handOff(_ entity: Entity, ctx: GameContext) {
        let lane = ctx.world.map.nearestLane(to: entity.position)
        let path = ctx.world.map.path(lane, for: entity.team)
        entity.brain = LaneBrain(path: path, startIndex: path.nextWaypointIndex(from: entity.position))
    }
}

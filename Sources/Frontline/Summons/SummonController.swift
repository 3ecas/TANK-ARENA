import CoreGraphics

/// Spawns summoned units, enforces active caps and expires them when their lifetime ends.
@MainActor
final class SummonController {
    unowned let ctx: GameContext
    private var nextGroup = 1

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func activeCount(_ type: SummonType, owner: Hero) -> Int {
        let units = ctx.world.entities.filter {
            $0.isAlive && !$0.isRemoved && $0.ownerId == owner.id && $0.summonType == type
        }
        if type == .squad {
            return Set(units.compactMap { $0.summonGroup }).count
        }
        return units.count
    }

    func canSummon(_ type: SummonType, owner: Hero) -> Bool {
        activeCount(type, owner: owner) < SummonConfig.cap(type)
    }

    // MARK: Spawning

    func spawnTank(owner: Hero, at point: CGPoint, power: CGFloat, lifetime: CGFloat) {
        let tank = makeSummon(.summonTank, type: .tank, owner: owner, at: point, power: power, lifetime: lifetime)
        let lane = ctx.world.map.nearestLane(to: point)
        let path = ctx.world.map.path(lane, for: owner.team)
        tank.brain = LaneBrain(path: path, startIndex: path.nextWaypointIndex(from: point))
        ctx.bus.publish(.explosion(position: point, radius: 60, big: false))
    }

    func spawnSquad(owner: Hero, at point: CGPoint, size: Int, lifetime: CGFloat) {
        let group = nextGroup
        nextGroup += 1
        for index in 0..<size {
            let offset = CGPoint(angle: CGFloat(index) * 2 * .pi / CGFloat(Swift.max(size, 1)), length: 30)
            let soldier = makeSummon(.squadSoldier, type: .squad, owner: owner, at: point + offset,
                                     power: 1, lifetime: lifetime)
            soldier.summonGroup = group
            soldier.brain = SummonBrain(ownerId: owner.id, slot: index, slotCount: size)
        }
        ctx.bus.publish(.projectileImpact(position: point, kind: .grenade))
    }

    func spawnHelicopter(owner: Hero, power: CGFloat, lifetime: CGFloat) {
        let start = owner.position - CGPoint(angle: owner.bodyAngle, length: 260)
        let heli = makeSummon(.helicopter, type: .helicopter, owner: owner, at: start.clamped(to: ctx.world.map.bounds),
                              power: power, lifetime: lifetime)
        heli.brain = SummonBrain(ownerId: owner.id, slot: 0, slotCount: 1)
    }

    func spawnSentry(owner: Hero, at point: CGPoint, power: CGFloat, lifetime: CGFloat) {
        let sentry = makeSummon(.sentry, type: .sentry, owner: owner, at: point, power: power, lifetime: lifetime)
        sentry.brain = GuardBrain()
    }

    private func makeSummon(_ kind: EntityKind, type: SummonType, owner: Hero, at point: CGPoint,
                            power: CGFloat, lifetime: CGFloat) -> Entity {
        let unit = ctx.factory.makeUnit(kind, team: owner.team, at: point)
        unit.ownerId = owner.id
        unit.summonType = type
        unit.lifetime = lifetime
        unit.bodyAngle = owner.bodyAngle
        unit.aimAngle = owner.bodyAngle
        if power != 1 { unit.scaleStats(hp: power, damage: power) }
        return unit
    }

    // MARK: Lifetimes

    func update(dt: CGFloat) {
        for entity in ctx.world.entities where entity.isAlive && !entity.isRemoved {
            guard let remaining = entity.lifetime else { continue }
            let next = remaining - dt
            entity.lifetime = next
            if next <= 0 {
                entity.isRemoved = true
                if entity.isArmored {
                    ctx.bus.publish(.explosion(position: entity.position, radius: entity.radius, big: false))
                }
            }
        }
    }
}

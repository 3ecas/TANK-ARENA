import CoreGraphics

struct DamageInfo {
    var amount: CGFloat
    var sourceId: Int?
    var team: Team
    var vsArmored: CGFloat = 1
    /// Extra multiplier against structures (call-ins deal reduced structure damage).
    var structureMultiplier: CGFloat = 1
}

/// Applies damage and healing, tracks attackers and publishes damage / kill events.
@MainActor
final class DamageSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    @discardableResult
    func apply(_ info: DamageInfo, to target: Entity) -> CGFloat {
        guard target.isAlive, !target.isRemoved, !target.isInvulnerable,
              info.team.isHostile(to: target.team) else { return 0 }
        var amount = info.amount
        if target.isArmored { amount *= info.vsArmored }
        if target is Structure { amount *= info.structureMultiplier }
        amount *= 100 / (100 + Swift.max(0, target.armor))
        amount = Swift.max(1, amount)
        target.hp -= amount

        let world = ctx.world
        let source = world.entity(info.sourceId)
        let creditId = source.map { $0.ownerId ?? $0.id }
        if let source = source {
            target.lastAttackerId = source.id
        }
        if let creditId = creditId, world.entity(creditId) is Hero {
            target.recentHeroAttackers[creditId] = world.time
        }
        ctx.bus.publish(.damaged(targetId: target.id, sourceId: info.sourceId, amount: amount,
                                 position: target.position))
        if let attacker = source as? Hero, target is Hero {
            ctx.bus.publish(.heroAttackedHero(attackerId: attacker.id, victimId: target.id))
        }
        if target.hp <= 0 {
            target.hp = 0
            target.velocity = .zero
            ctx.bus.publish(.killed(victimId: target.id, killerId: creditId))
        }
        return amount
    }

    /// Damages every hostile entity in a circle. Returns the entities hit.
    @discardableResult
    func applyArea(center: CGPoint, radius: CGFloat, info: DamageInfo, hitsAir: Bool = true) -> [Entity] {
        var hit: [Entity] = []
        for entity in ctx.world.grid.query(center: center, radius: radius) {
            guard entity.isAlive, info.team.isHostile(to: entity.team) else { continue }
            if entity.isFlying && !hitsAir { continue }
            if apply(info, to: entity) > 0 { hit.append(entity) }
        }
        return hit
    }

    /// Instant heal. Publishes a heal number when `announce` is true.
    func heal(_ target: Entity, amount: CGFloat, announce: Bool = true) {
        guard target.isAlive, amount > 0 else { return }
        let before = target.hp
        target.hp = Swift.min(target.maxHp, target.hp + amount)
        let healed = target.hp - before
        if announce && healed >= 1 {
            ctx.bus.publish(.healed(targetId: target.id, amount: healed, position: target.position))
        }
    }
}

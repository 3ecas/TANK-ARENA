import CoreGraphics

enum CastResult {
    case success, noAbility, onCooldown, noCommandPoints, unavailable, blocked

    var message: String? {
        switch self {
        case .success, .noAbility: return nil
        case .onCooldown: return "Ability on cooldown"
        case .noCommandPoints: return "Not enough Command Points"
        case .unavailable: return "Can't use abilities right now"
        case .blocked: return "Limit reached"
        }
    }
}

/// Validates and performs ability casts; ticks cooldowns.
@MainActor
final class AbilitySystem {
    unowned let ctx: GameContext
    private let registry = AbilityRegistry()

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        for hero in ctx.world.heroes { hero.loadout.tick(dt) }
    }

    /// Checks whether the ability in `slot` could be cast right now.
    func readiness(_ hero: Hero, slot: Int) -> CastResult {
        guard let id = hero.loadout.ability(inSlot: slot) else { return .noAbility }
        guard hero.isAlive, !hero.status.isStunned else { return .unavailable }
        if hero.loadout.cooldown(of: id) > 0 { return .onCooldown }
        if hero.commandPoints < AbilityCatalog.def(id).cpCost { return .noCommandPoints }
        return .success
    }

    @discardableResult
    func tryCast(_ hero: Hero, slot: Int, target: CGPoint) -> CastResult {
        let ready = readiness(hero, slot: slot)
        guard ready == .success, let id = hero.loadout.ability(inSlot: slot),
              let ability = registry.ability(for: id) else { return ready }
        let def = AbilityCatalog.def(id)
        let rank = Swift.max(1, hero.loadout.rank(of: id))
        let aimed = AbilityGeometry.clampedTarget(def, caster: hero.position, cursor: target)
        let cast = AbilityCast(caster: hero, target: aimed, rank: rank, def: def)
        guard ability.cast(cast, ctx: ctx) else { return .blocked }

        hero.loadout.setCooldown(id, effectiveCooldown(def, rank: rank, hero: hero))
        ctx.commandPoints.spend(hero, def.cpCost)
        if hero.isRecalling { ctx.recall.cancel(hero) }
        ctx.bus.publish(.abilityCast(heroId: hero.id, ability: id, target: aimed))
        return .success
    }

    func effectiveCooldown(_ def: AbilityDef, rank: Int, hero: Hero) -> CGFloat {
        var cooldown = def.cooldown(at: rank) * (1 - hero.stats.cooldownReduction)
        if def.isCallIn {
            cooldown *= ctx.objectives.callInCooldownMultiplier(for: hero.team)
        }
        return cooldown
    }
}

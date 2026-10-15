import CoreGraphics

/// Follows the hero's build order at base, equips the loadout and spends ability points.
@MainActor
final class AIShopper {
    let hero: Hero
    let build: AIBuild
    unowned let ctx: GameContext
    private var stepIndex = 0

    init(hero: Hero, build: AIBuild, ctx: GameContext) {
        self.hero = hero
        self.build = build
        self.ctx = ctx
    }

    /// Cost of the next purchase in the build (nil when the build is complete).
    func nextCost() -> Int? {
        var index = stepIndex
        while index < build.purchases.count {
            let step = build.purchases[index]
            if !isDone(step) { return cost(of: step) }
            index += 1
        }
        return nil
    }

    func wantsToShop() -> Bool {
        guard let cost = nextCost() else { return false }
        return hero.gold >= cost + 250
    }

    func shop() {
        guard ctx.shop.isAtShop(hero) else { return }
        while stepIndex < build.purchases.count {
            let step = build.purchases[stepIndex]
            if isDone(step) { stepIndex += 1; continue }
            guard let cost = cost(of: step), hero.gold >= cost else { break }
            _ = perform(step)
            stepIndex += 1
        }
        equipBuild()
    }

    func spendAbilityPoints() {
        while hero.abilityPoints > 0 {
            var bestSlot: Int?
            var bestRank = AbilityDef.maxRank
            for slot in 0..<Loadout.slotCount {
                guard let id = hero.loadout.ability(inSlot: slot) else { continue }
                let rank = hero.loadout.rank(of: id)
                if rank < bestRank { bestRank = rank; bestSlot = slot }
            }
            guard let slot = bestSlot, LoadoutManager.spendPoint(onSlot: slot, hero: hero) else { return }
        }
    }

    private func equipBuild() {
        var preferred = Array(build.startingAbilities.prefix(3))
        if hero.loadout.owns(build.ultimate) {
            preferred.append(build.ultimate)
        } else if build.startingAbilities.count > 3 {
            preferred.append(build.startingAbilities[3])
        }
        for (slot, id) in preferred.enumerated() where hero.loadout.owns(id) {
            if hero.loadout.ability(inSlot: slot) != id {
                _ = ctx.shop.equip(id, slot: slot, for: hero)
            }
        }
    }

    private func isDone(_ step: BuildStep) -> Bool {
        switch step {
        case .ability(let id): return hero.loadout.rank(of: id) >= AbilityDef.maxRank
        case .weapon(let id): return hero.weaponId == id
        case .gear(let id):
            return hero.gear.contains(id) || hero.gear.contains { GearCatalog.def($0).requires == id }
        }
    }

    private func cost(of step: BuildStep) -> Int? {
        switch step {
        case .ability(let id): return AbilityShop.price(of: id, for: hero)
        case .weapon(let id): return WeaponCatalog.def(id).cost
        case .gear(let id): return GearCatalog.def(id).cost
        }
    }

    private func perform(_ step: BuildStep) -> ShopResult {
        switch step {
        case .ability(let id): return ctx.shop.buyAbility(id, for: hero)
        case .weapon(let id): return ctx.shop.buyWeapon(id, for: hero)
        case .gear(let id): return ctx.shop.buyGear(id, for: hero)
        }
    }
}

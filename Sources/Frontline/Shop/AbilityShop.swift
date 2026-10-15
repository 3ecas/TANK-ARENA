/// Buying abilities: first purchase unlocks (and auto-equips into a free slot), later purchases rank up.
@MainActor
enum AbilityShop {
    static func price(of id: AbilityID, for hero: Hero) -> Int? {
        let def = AbilityCatalog.def(id)
        let rank = hero.loadout.rank(of: id)
        if rank == 0 { return def.goldCost }
        if rank >= AbilityDef.maxRank { return nil }
        return def.upgradeCost
    }

    static func buy(_ id: AbilityID, hero: Hero) -> ShopResult {
        let def = AbilityCatalog.def(id)
        guard let cost = price(of: id, for: hero) else { return .failure("\(def.name) is already max rank") }
        guard hero.gold >= cost else { return .failure("Not enough gold (\(cost) needed)") }
        hero.gold -= cost
        if hero.loadout.owns(id) {
            _ = hero.loadout.rankUp(id)
            return .success("\(def.name) upgraded to rank \(hero.loadout.rank(of: id))")
        }
        hero.loadout.learn(id)
        if let slot = hero.loadout.firstEmptySlot {
            hero.loadout.equip(id, slot: slot)
            return .success("\(def.name) bought and equipped to \(Loadout.slotLabels[slot])")
        }
        return .success("\(def.name) bought - equip it to a slot")
    }
}

import CoreGraphics

/// Rules for changing a hero's loadout: equipping only at base, spending ability points anywhere.
@MainActor
enum LoadoutManager {
    static func canEdit(_ hero: Hero, map: MapLayout) -> Bool {
        hero.isAlive && map.isInBase(hero.position, team: hero.team)
    }

    static func equip(_ id: AbilityID, slot: Int, hero: Hero, map: MapLayout) -> ShopResult {
        guard hero.loadout.owns(id) else { return .failure("You don't own that ability") }
        guard canEdit(hero, map: map) else { return .failure("Loadout can only be changed at base") }
        hero.loadout.equip(id, slot: slot)
        return .success("\(AbilityCatalog.def(id).name) equipped to \(Loadout.slotLabels[slot])")
    }

    /// Spends one ability point to rank up the ability in `slot`.
    @discardableResult
    static func spendPoint(onSlot slot: Int, hero: Hero) -> Bool {
        guard hero.abilityPoints > 0, let id = hero.loadout.ability(inSlot: slot) else { return false }
        guard hero.loadout.rankUp(id) else { return false }
        hero.abilityPoints -= 1
        return true
    }

    /// Gives a hero its starting abilities, equipped in order.
    static func grantStarting(_ abilities: [AbilityID], to hero: Hero) {
        for (index, id) in abilities.prefix(Loadout.slotCount).enumerated() {
            hero.loadout.learn(id)
            hero.loadout.equip(id, slot: index)
        }
    }
}

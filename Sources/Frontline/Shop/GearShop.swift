/// Buying gear (6 slots) with basic -> advanced upgrade paths.
@MainActor
enum GearShop {
    static func canBuy(_ id: GearID, hero: Hero) -> Bool {
        let def = GearCatalog.def(id)
        if hero.gear.contains(id) { return false }
        if let required = def.requires { return hero.gear.contains(required) }
        return hero.gear.count < HeroConfig.maxGearSlots
    }

    static func buy(_ id: GearID, hero: Hero) -> ShopResult {
        let def = GearCatalog.def(id)
        if hero.gear.contains(id) { return .failure("You already own \(def.name)") }
        if let required = def.requires, !hero.gear.contains(required) {
            return .failure("Requires \(GearCatalog.def(required).name)")
        }
        if def.requires == nil && hero.gear.count >= HeroConfig.maxGearSlots {
            return .failure("All 6 gear slots are full")
        }
        guard hero.gold >= def.cost else { return .failure("Not enough gold (\(def.cost) needed)") }
        hero.gold -= def.cost
        if let required = def.requires, let index = hero.gear.firstIndex(of: required) {
            hero.gear[index] = id
            return .success("Upgraded to \(def.name)")
        }
        hero.gear.append(id)
        return .success("\(def.name) bought")
    }
}

/// Buying and switching primary weapons.
@MainActor
enum WeaponShop {
    static func buyOrSelect(_ id: WeaponID, hero: Hero) -> ShopResult {
        let def = WeaponCatalog.def(id)
        if hero.ownedWeapons.contains(id) {
            guard hero.weaponId != id else { return .failure("\(def.name) is already equipped") }
            select(id, hero: hero)
            return .success("\(def.name) equipped")
        }
        guard hero.gold >= def.cost else { return .failure("Not enough gold (\(def.cost) needed)") }
        hero.gold -= def.cost
        hero.ownedWeapons.insert(id)
        select(id, hero: hero)
        return .success("\(def.name) bought and equipped")
    }

    private static func select(_ id: WeaponID, hero: Hero) {
        hero.weaponId = id
        hero.reloadTimer = 0
        hero.targetId = nil
        StatCalculator.apply(to: hero)
        hero.ammo = hero.stats.magSize
    }
}

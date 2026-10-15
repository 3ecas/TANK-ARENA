import CoreGraphics

/// Entry point for every purchase (player UI and AI). Purchases are only allowed at base.
@MainActor
final class ShopService {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func isAtShop(_ hero: Hero) -> Bool {
        LoadoutManager.canEdit(hero, map: ctx.world.map)
    }

    func buyAbility(_ id: AbilityID, for hero: Hero) -> ShopResult {
        guard isAtShop(hero) else { return .failure("The shop is only available at base") }
        return finish(AbilityShop.buy(id, hero: hero), hero: hero)
    }

    func buyWeapon(_ id: WeaponID, for hero: Hero) -> ShopResult {
        guard isAtShop(hero) else { return .failure("The shop is only available at base") }
        return finish(WeaponShop.buyOrSelect(id, hero: hero), hero: hero)
    }

    func buyGear(_ id: GearID, for hero: Hero) -> ShopResult {
        guard isAtShop(hero) else { return .failure("The shop is only available at base") }
        return finish(GearShop.buy(id, hero: hero), hero: hero)
    }

    func equip(_ id: AbilityID, slot: Int, for hero: Hero) -> ShopResult {
        LoadoutManager.equip(id, slot: slot, hero: hero, map: ctx.world.map)
    }

    private func finish(_ result: ShopResult, hero: Hero) -> ShopResult {
        if result.isSuccess {
            StatCalculator.apply(to: hero)
            ctx.bus.publish(.purchase(heroId: hero.id))
        }
        return result
    }
}

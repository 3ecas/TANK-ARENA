import CoreGraphics

/// Derives hero stats from level, weapon and gear.
@MainActor
enum StatCalculator {
    static func compute(for hero: Hero) -> HeroStats {
        let levelBonus = CGFloat(hero.level - 1)
        var bonus = StatBonuses()
        for id in hero.gear {
            bonus = bonus + GearCatalog.def(id).bonuses
        }
        let weapon = hero.weapon
        var stats = HeroStats()
        stats.maxHp = HeroConfig.baseHp + HeroConfig.hpPerLevel * levelBonus + bonus.maxHp
        stats.armor = HeroConfig.baseArmor + HeroConfig.armorPerLevel * levelBonus + bonus.armor
        stats.speed = (HeroConfig.baseSpeed + bonus.speed) * weapon.speedMultiplier
        stats.damage = weapon.totalDamage * (1 + HeroConfig.damagePerLevel * levelBonus + bonus.damagePct)
        stats.range = weapon.range * (1 + bonus.rangePct)
        stats.fireInterval = weapon.interval / (1 + bonus.fireRatePct)
        stats.magSize = Swift.max(1, Int((CGFloat(weapon.magSize) * (1 + bonus.magPct)).rounded()))
        stats.reloadTime = weapon.reloadTime
        stats.pellets = weapon.pellets
        stats.spread = weapon.spread
        stats.hpRegen = HeroConfig.baseRegen + HeroConfig.regenPerLevel * levelBonus + bonus.hpRegen
        stats.cooldownReduction = Swift.min(HeroConfig.maxCooldownReduction, bonus.cooldownReduction)
        stats.abilityPower = 1 + HeroConfig.abilityPowerPerLevel * levelBonus + bonus.abilityPower
        return stats
    }

    /// Recomputes stats and writes them into the hero's entity fields.
    static func apply(to hero: Hero) {
        let stats = compute(for: hero)
        let oldMax = hero.maxHp
        hero.stats = stats
        hero.maxHp = stats.maxHp
        if hero.isAlive {
            hero.hp = Swift.min(stats.maxHp, hero.hp + Swift.max(0, stats.maxHp - oldMax))
        }
        hero.armor = stats.armor
        hero.baseSpeed = stats.speed
        hero.hpRegen = stats.hpRegen
        hero.attack = AttackStats(damage: stats.damage, range: stats.range, interval: stats.fireInterval,
                                  vsArmored: HeroConfig.weaponVsArmored)
        hero.ammo = Swift.min(hero.ammo, stats.magSize)
    }
}

import CoreGraphics

enum HeroConfig {
    static let baseHp: CGFloat = 620
    static let hpPerLevel: CGFloat = 85
    static let baseArmor: CGFloat = 20
    static let armorPerLevel: CGFloat = 2.5
    static let baseSpeed: CGFloat = 175
    static let radius: CGFloat = 13
    static let sight: CGFloat = 760
    static let baseRegen: CGFloat = 2.5
    static let regenPerLevel: CGFloat = 0.35
    static let damagePerLevel: CGFloat = 0.035
    static let abilityPowerPerLevel: CGFloat = 0.04
    static let maxLevel = 18
    static let maxCooldownReduction: CGFloat = 0.4
    static let maxGearSlots = 6

    /// Respawn time = base + perLevel * level.
    static let respawnBase: CGFloat = 6
    static let respawnPerLevel: CGFloat = 2

    /// Hero weapons do reduced damage to armored targets.
    static let weaponVsArmored: CGFloat = 0.75

    static let startingGold = 600

    /// XP required to go from `level` to `level + 1`.
    static func xpToNext(level: Int) -> CGFloat {
        100 + 70 * CGFloat(level - 1)
    }

    static let baseUnitStats = UnitStats(
        maxHp: baseHp, armor: baseArmor, speed: baseSpeed, radius: radius, sight: sight,
        attack: nil, goldBounty: 300, xpBounty: 150, hpRegen: baseRegen)
}

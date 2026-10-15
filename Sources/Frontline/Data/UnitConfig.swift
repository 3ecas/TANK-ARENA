import CoreGraphics

/// Weapon / attack profile of any unit or structure.
struct AttackStats {
    var damage: CGFloat
    var range: CGFloat
    var interval: CGFloat
    /// 0 means hitscan (instant hit with a tracer).
    var projectileSpeed: CGFloat = 0
    var splashRadius: CGFloat = 0
    /// Damage multiplier against armored targets (vehicles, structures).
    var vsArmored: CGFloat = 1
    var canHitAir: Bool = true
    var projectile: ProjectileKind = .bullet
}

/// Base stats for a unit type.
struct UnitStats {
    var maxHp: CGFloat
    var armor: CGFloat
    var speed: CGFloat
    var radius: CGFloat
    var sight: CGFloat
    var attack: AttackStats?
    var goldBounty: Int
    var xpBounty: CGFloat
    var isArmored: Bool = false
    var isFlying: Bool = false
    var hpRegen: CGFloat = 0
}

enum UnitCatalog {
    static func stats(for kind: EntityKind) -> UnitStats {
        switch kind {
        case .hero: return HeroConfig.baseUnitStats
        case .rifleman: return rifleman
        case .rocketSoldier: return rocketSoldier
        case .tank: return tank
        case .apc: return apc
        case .superTank: return superTank
        case .bunker: return StructureConfig.bunker
        case .barracks: return StructureConfig.barracks
        case .hq: return StructureConfig.hq
        case .sentry: return sentry
        case .squadSoldier: return squadSoldier
        case .summonTank: return summonTank
        case .helicopter: return helicopter
        case .mercenary: return mercenary
        case .heavyMercenary: return heavyMercenary
        case .depotGuardian: return depotGuardian
        }
    }

    static let rifleman = UnitStats(
        maxHp: 230, armor: 5, speed: 90, radius: 11, sight: 450,
        attack: AttackStats(damage: 13, range: 300, interval: 0.85, vsArmored: 0.7),
        goldBounty: 22, xpBounty: 32)

    static let rocketSoldier = UnitStats(
        maxHp: 190, armor: 0, speed: 85, radius: 11, sight: 450,
        attack: AttackStats(damage: 34, range: 360, interval: 2.0, projectileSpeed: 520,
                            vsArmored: 2.0, projectile: .rocket),
        goldBounty: 26, xpBounty: 34)

    static let tank = UnitStats(
        maxHp: 1500, armor: 45, speed: 62, radius: 26, sight: 500,
        attack: AttackStats(damage: 70, range: 420, interval: 2.3, projectileSpeed: 650, splashRadius: 50,
                            vsArmored: 1.3, canHitAir: false, projectile: .shell),
        goldBounty: 70, xpBounty: 90, isArmored: true)

    static let apc = UnitStats(
        maxHp: 950, armor: 35, speed: 80, radius: 22, sight: 450,
        attack: AttackStats(damage: 9, range: 320, interval: 0.3, vsArmored: 0.8),
        goldBounty: 50, xpBounty: 60, isArmored: true)

    static let superTank = UnitStats(
        maxHp: 5000, armor: 70, speed: 55, radius: 38, sight: 650,
        attack: AttackStats(damage: 140, range: 480, interval: 2.0, projectileSpeed: 700, splashRadius: 80,
                            vsArmored: 1.5, canHitAir: false, projectile: .shell),
        goldBounty: 300, xpBounty: 250, isArmored: true)

    static let sentry = UnitStats(
        maxHp: 420, armor: 20, speed: 0, radius: 14, sight: 520,
        attack: AttackStats(damage: 16, range: 460, interval: 0.3, vsArmored: 0.8),
        goldBounty: 40, xpBounty: 40, isArmored: true)

    static let squadSoldier = UnitStats(
        maxHp: 300, armor: 10, speed: 150, radius: 11, sight: 450,
        attack: AttackStats(damage: 16, range: 330, interval: 0.7, vsArmored: 0.7),
        goldBounty: 15, xpBounty: 20)

    static let summonTank = UnitStats(
        maxHp: 1800, armor: 50, speed: 75, radius: 26, sight: 550,
        attack: AttackStats(damage: 85, range: 450, interval: 2.0, projectileSpeed: 700, splashRadius: 60,
                            vsArmored: 1.3, canHitAir: false, projectile: .shell),
        goldBounty: 80, xpBounty: 80, isArmored: true)

    static let helicopter = UnitStats(
        maxHp: 950, armor: 25, speed: 190, radius: 24, sight: 700,
        attack: AttackStats(damage: 22, range: 460, interval: 0.22, vsArmored: 0.9),
        goldBounty: 100, xpBounty: 80, isArmored: true, isFlying: true)

    static let mercenary = UnitStats(
        maxHp: 520, armor: 10, speed: 100, radius: 12, sight: 400,
        attack: AttackStats(damage: 22, range: 280, interval: 0.9),
        goldBounty: 45, xpBounty: 55)

    static let heavyMercenary = UnitStats(
        maxHp: 1100, armor: 25, speed: 85, radius: 16, sight: 400,
        attack: AttackStats(damage: 45, range: 300, interval: 1.2, projectileSpeed: 500, projectile: .rocket),
        goldBounty: 80, xpBounty: 90)

    static let depotGuardian = UnitStats(
        maxHp: 9000, armor: 60, speed: 70, radius: 44, sight: 600,
        attack: AttackStats(damage: 180, range: 420, interval: 1.6, projectileSpeed: 650, splashRadius: 90,
                            projectile: .shell),
        goldBounty: 300, xpBounty: 400, isArmored: true)
}

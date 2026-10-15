import CoreGraphics

enum StructureConfig {
    static let bunker = UnitStats(
        maxHp: 3200, armor: 55, speed: 0, radius: 34, sight: 750,
        attack: AttackStats(damage: 125, range: 560, interval: 1.25, projectileSpeed: 750, projectile: .cannon),
        goldBounty: 150, xpBounty: 150, isArmored: true)

    static let barracks = UnitStats(
        maxHp: 2600, armor: 40, speed: 0, radius: 44, sight: 600,
        attack: nil, goldBounty: 100, xpBounty: 120, isArmored: true)

    static let hq = UnitStats(
        maxHp: 5200, armor: 60, speed: 0, radius: 70, sight: 800,
        attack: AttackStats(damage: 160, range: 620, interval: 1.1, projectileSpeed: 800, projectile: .cannon),
        goldBounty: 0, xpBounty: 0, isArmored: true)

    /// Distances along each lane (from the owning HQ) where structures are placed.
    static let barracksDistance: CGFloat = 520
    static let innerBunkerDistance: CGFloat = 1080
    static let outerBunkerDistance: CGFloat = 1720

    /// Seconds a bunker keeps focusing a hero that attacked an allied hero.
    static let heroAggroDuration: CGFloat = 2.5
    /// Gold given to every hero of the team that destroys a structure.
    static let teamGoldBunker = 150
    static let teamGoldBarracks = 100
    /// Wave buff for the team that destroyed the enemy barracks in a lane.
    static let barracksDownStatBonus: CGFloat = 0.3
}

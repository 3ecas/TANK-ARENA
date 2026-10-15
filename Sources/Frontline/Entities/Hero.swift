import CoreGraphics

/// A soldier hero: the player or an AI commander.
final class Hero: Entity {
    let name: String
    let isPlayer: Bool
    let spawnPoint: CGPoint

    // Progression
    var level = 1
    var xp: CGFloat = 0
    var gold: Int = HeroConfig.startingGold
    var goldRemainder: CGFloat = 0
    var commandPoints = 0
    var abilityPoints = 0

    // Equipment
    var weaponId: WeaponID = .assaultRifle
    var ownedWeapons: Set<WeaponID> = [.assaultRifle]
    var gear: [GearID] = []
    var loadout = Loadout()
    var stats = HeroStats()

    // Weapon state
    var ammo: Int = 30
    var reloadTimer: CGFloat = 0

    // Control state
    var aimPoint: CGPoint = .zero
    var respawnTimer: CGFloat = 0
    var recallTimer: CGFloat?

    // Scoreboard
    var kills = 0
    var deaths = 0
    var assists = 0
    var troopKills = 0

    init(id: Int, name: String, team: Team, isPlayer: Bool, spawn: CGPoint) {
        self.name = name
        self.isPlayer = isPlayer
        self.spawnPoint = spawn
        super.init(id: id, kind: .hero, team: team, position: spawn, stats: HeroConfig.baseUnitStats)
        aimPoint = spawn + CGPoint(angle: bodyAngle, length: 100)
    }

    var weapon: WeaponDef { WeaponCatalog.def(weaponId) }
    var isReloading: Bool { reloadTimer > 0 }
    var isRecalling: Bool { recallTimer != nil }
    var xpToNextLevel: CGFloat { HeroConfig.xpToNext(level: level) }
    var respawnDuration: CGFloat { HeroConfig.respawnBase + HeroConfig.respawnPerLevel * CGFloat(level) }
}

import CoreGraphics

/// One soldier: the player or a bot. Pure game state (no rendering).
@MainActor
final class Soldier {
    let id: Int
    let team: Team
    let name: String
    let isPlayer: Bool
    let radius = GameConfig.soldierRadius

    var position: CGPoint
    var velocity: CGPoint = .zero
    /// Direction the soldier (and weapon) faces, radians.
    var facing: CGFloat
    var hp: CGFloat = GameConfig.maxHp
    var respawnsLeft = GameConfig.respawnsPerSoldier
    var respawnTimer: CGFloat = 0
    var spawnProtection: CGFloat = GameConfig.spawnProtection

    // Loadout: primary + pistol, one grenade, knife.
    var weapons: [WeaponState]
    var activeIndex = 0
    var grenade: GrenadeType?
    var knifeCooldown: CGFloat = 0
    var knifeSwing: CGFloat = 0
    var switchTimer: CGFloat = 0

    // Status
    var blindTime: CGFloat = 0
    var blindDuration: CGFloat = 1
    var stunTime: CGFloat = 0

    // Intent written by the player controller or the bot AI
    var moveDir: CGPoint = .zero
    var aimPoint: CGPoint
    /// Trigger held (automatic weapons keep firing).
    var wantsToFire = false
    /// Trigger pressed this frame (semi-automatic weapons fire once).
    var firePressed = false

    var timeSinceShot: CGFloat = 10
    var kills = 0
    var deaths = 0
    var lastAttackerId: Int?

    init(id: Int, team: Team, name: String, isPlayer: Bool, position: CGPoint, primary: WeaponID,
         grenade: GrenadeType) {
        self.id = id
        self.team = team
        self.name = name
        self.isPlayer = isPlayer
        self.position = position
        self.facing = team == .blue ? 0 : .pi
        self.aimPoint = position + CGPoint(x: team == .blue ? 100 : -100, y: 0)
        self.weapons = [WeaponState(primary), WeaponState(.pistol)]
        self.grenade = grenade
    }

    var isAlive: Bool { hp > 0 }
    /// Dead but will come back.
    var isAwaitingRespawn: Bool { !isAlive && respawnsLeft > 0 }
    /// Dead for good.
    var isEliminated: Bool { !isAlive && respawnsLeft <= 0 }
    var activeWeapon: WeaponState { weapons[activeIndex] }
    var isStunned: Bool { stunTime > 0 }
    var isBlind: Bool { blindTime > 0 }
    var hpFraction: CGFloat { (hp / GameConfig.maxHp).clamped(0, 1) }

    /// Fresh loadout and full health (spawn / respawn).
    func resetLoadout(primary: WeaponID, grenade: GrenadeType) {
        hp = GameConfig.maxHp
        weapons = [WeaponState(primary), WeaponState(.pistol)]
        activeIndex = 0
        self.grenade = grenade
        blindTime = 0
        stunTime = 0
        knifeCooldown = 0
        switchTimer = 0
        wantsToFire = false
        firePressed = false
        spawnProtection = GameConfig.spawnProtection
    }
}

import CoreGraphics

/// Base class for every unit and structure. Pure game state: no rendering.
@MainActor
class Entity {
    let id: Int
    let kind: EntityKind
    var team: Team
    var position: CGPoint
    var radius: CGFloat
    var maxHp: CGFloat
    var hp: CGFloat
    var armor: CGFloat
    var baseSpeed: CGFloat
    var sightRange: CGFloat
    var hpRegen: CGFloat
    var attack: AttackStats?
    var attackCooldown: CGFloat = 0
    var goldBounty: Int
    var xpBounty: CGFloat
    let isArmored: Bool
    let isFlying: Bool
    var isStatic: Bool { baseSpeed <= 0 }

    /// Current attack target (set by brains / controllers, used by combat systems).
    var targetId: Int?
    /// Desired movement direction (length <= 1), written by brains / controllers.
    var moveDir: CGPoint = .zero
    var velocity: CGPoint = .zero
    /// Hull / body orientation (radians).
    var bodyAngle: CGFloat = 0
    /// Weapon / turret orientation (radians).
    var aimAngle: CGFloat = 0

    var status = StatusEffects()
    var isInvulnerable = false
    var brain: UnitBrain?
    /// Hero who summoned this unit, if any.
    var ownerId: Int?
    var summonType: SummonType?
    var summonGroup: Int?
    /// Remaining life for temporary units (nil = permanent).
    var lifetime: CGFloat?
    var homePosition: CGPoint
    var lastAttackerId: Int?
    /// Hero id -> world time of their last damage (assist tracking).
    var recentHeroAttackers: [Int: CGFloat] = [:]
    /// Set when the entity should be removed from the world at the end of the frame.
    var isRemoved = false
    /// Time since the last shot (used by renderers for muzzle flashes / recoil).
    var timeSinceShot: CGFloat = 10

    var isAlive: Bool { hp > 0 }
    var hpFraction: CGFloat { maxHp > 0 ? (hp / maxHp).clamped(0, 1) : 0 }

    init(id: Int, kind: EntityKind, team: Team, position: CGPoint, stats: UnitStats) {
        self.id = id
        self.kind = kind
        self.team = team
        self.position = position
        self.homePosition = position
        self.radius = stats.radius
        self.maxHp = stats.maxHp
        self.hp = stats.maxHp
        self.armor = stats.armor
        self.baseSpeed = stats.speed
        self.sightRange = stats.sight
        self.hpRegen = stats.hpRegen
        self.attack = stats.attack
        self.goldBounty = stats.goldBounty
        self.xpBounty = stats.xpBounty
        self.isArmored = stats.isArmored
        self.isFlying = stats.isFlying
        if team == .red {
            bodyAngle = -.pi * 3 / 4
            aimAngle = bodyAngle
        } else if team == .blue {
            bodyAngle = .pi / 4
            aimAngle = bodyAngle
        }
    }

    /// Scales max HP and attack damage (wave scaling, summon rank).
    func scaleStats(hp hpMultiplier: CGFloat, damage damageMultiplier: CGFloat) {
        maxHp *= hpMultiplier
        hp = maxHp
        attack?.damage *= damageMultiplier
    }
}

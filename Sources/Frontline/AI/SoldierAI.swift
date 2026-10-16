import CoreGraphics

enum CombatPhase {
    /// Running to a cover spot.
    case moving
    /// Hidden behind cover (reloading, waiting).
    case covered
    /// Stepped out of cover to shoot.
    case peeking
}

/// Bot brain. Out of combat it moves with its squad; in combat it fights from cover
/// (peek, shoot, duck back), strafes when no cover is near, knifes up close and throws grenades.
@MainActor
final class SoldierAI {
    let soldier: Soldier
    unowned let ctx: BattleContext
    let services: BotServices
    let follower = PathFollower()
    weak var squad: Squad?

    // Perception and memory
    var targetId: Int?
    /// The current target has its back turned (or is blinded): go for the kill instead of hiding.
    var targetExposed = false
    var reactionTimer: CGFloat = 0
    var threatPosition: CGPoint?
    var threatTime: CGFloat = -100
    var threatVelocity: CGPoint = .zero
    /// Where to look while idle / walking, refreshed on each think step (line-of-sight checks are not cheap).
    var cachedWatch: CGPoint?
    var cachedGlance: CGPoint?
    var aimOffset: CGPoint = .zero
    var strafeSign: CGFloat = 1
    var strafeTimer: CGFloat = 0
    private var thinkTimer = CGFloat.random(in: 0...AIConfig.thinkInterval)

    // Cover combat
    var cover: CoverSpot?
    var coverThreat: CGPoint = .zero
    var coverRetryTimer: CGFloat = 0
    var phase: CombatPhase = .moving
    var phaseTimer: CGFloat = 0
    /// Lone flanker outside any squad.
    var isRogue = false
    var rogueRoute: [CGPoint] = []
    var rogueDeadline: CGFloat = 0
    /// Where the bot is heading out of combat (used by the squad formation).
    var travelGoal: CGPoint?

    init(soldier: Soldier, ctx: BattleContext, services: BotServices) {
        self.soldier = soldier
        self.ctx = ctx
        self.services = services
    }

    var hasRecentThreat: Bool {
        threatPosition != nil && ctx.world.time - threatTime < AIConfig.combatMemory
    }

    func update(dt: CGFloat) {
        guard soldier.isAlive else {
            reset()
            return
        }
        thinkTimer -= dt
        reactionTimer -= dt
        strafeTimer -= dt
        phaseTimer -= dt
        coverRetryTimer -= dt
        if thinkTimer <= 0 {
            thinkTimer = AIConfig.thinkInterval * CGFloat.random(in: 0.8...1.2)
            think()
            refreshAwareness()
        }
        soldier.wantsToInteract = false
        soldier.isEngaged = hasRecentThreat
        if bombDuty(dt: dt) { return }
        if hasRecentThreat, let threat = threatPosition {
            combat(threat: threat, dt: dt)
        } else {
            soldier.wantsToFire = false
            soldier.firePressed = false
            cover = nil
            groupMove(dt: dt)
        }
    }

    private func reset() {
        targetId = nil
        targetExposed = false
        threatPosition = nil
        cover = nil
        travelGoal = nil
        rogueRoute.removeAll()
        follower.clear()
    }

    // MARK: Decisions

    private func think() {
        if strafeTimer <= 0 {
            strafeSign = Bool.random() ? 1 : -1
            strafeTimer = CGFloat.random(in: AIConfig.strafeIntervalMin...AIConfig.strafeIntervalMax)
        }
        let now = ctx.world.time
        if let pick = pickTarget() {
            let enemy = pick.0, exposed = pick.1
            if enemy.id != targetId {
                reactionTimer = AIConfig.reactionTime * CGFloat.random(in: 0.8...1.3) * (exposed ? 0.6 : 1)
            }
            targetId = enemy.id
            targetExposed = exposed
            threatPosition = enemy.position
            threatVelocity = enemy.velocity
            threatTime = now
            services.intel.report(by: soldier.team, enemy: enemy, time: now)
            squad?.reportContact(enemy.position, time: now)
            let distance = enemy.position.distance(to: soldier.position)
            // An unaware target gives time for a calmer, more accurate shot.
            let error = (AIConfig.aimErrorBase + AIConfig.aimErrorPerDistance * distance) * (exposed ? 0.6 : 1)
            aimOffset = CGPoint(x: CGFloat.random(in: -error...error), y: CGFloat.random(in: -error...error))
            chooseWeapon()
            if !exposed { considerGrenade(at: enemy.position, distance: distance) }
        } else {
            targetId = nil
            targetExposed = false
            if let threat = threatPosition, now - threatTime > 0.6, hasRecentThreat {
                considerGrenade(at: threat, distance: threat.distance(to: soldier.position))
            }
            if !hasRecentThreat && soldier.activeWeapon.magazineFraction < AIConfig.reloadThreshold {
                services.weapons.reload(soldier)
            }
        }
    }

    /// Visible enemy to fight: an enemy with its back turned is preferred over a closer one that is watching.
    private func pickTarget() -> (Soldier, Bool)? {
        var best: (Soldier, Bool)?
        var bestScore = CGFloat.greatestFiniteMagnitude
        for enemy in services.vision.visibleEnemies(for: soldier) {
            let exposed = services.vision.isUnaware(enemy, of: soldier)
            let score = enemy.position.distance(to: soldier.position) - (exposed ? AIConfig.exposedTargetBonus : 0)
            if score < bestScore {
                bestScore = score
                best = (enemy, exposed)
            }
        }
        return best
    }

    /// Primary unless it is completely out of ammo.
    private func chooseWeapon() {
        if soldier.activeIndex == 0 && soldier.weapons[0].isEmpty {
            services.weapons.switchTo(soldier, index: 1)
        }
    }

    private func considerGrenade(at point: CGPoint, distance: CGFloat) {
        guard soldier.grenade != nil, distance >= AIConfig.grenadeMinDistance,
              distance <= GrenadeConfig.maxThrowDistance, CGFloat.random(in: 0...1) < AIConfig.grenadeChance
        else { return }
        let error = CGPoint(x: CGFloat.random(in: -40...40), y: CGFloat.random(in: -40...40))
        services.grenades.throwGrenade(soldier, at: point + error)
    }

    func moveToward(_ point: CGPoint, dt: CGFloat) {
        soldier.moveDir = follower.direction(from: soldier.position, to: point, nav: ctx.world.nav, dt: dt) ?? .zero
    }
}

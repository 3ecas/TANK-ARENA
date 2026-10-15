import CoreGraphics

/// Bot brain: advance along an attack route, fight the nearest visible enemy (strafing, reloading,
/// knifing at close range, throwing grenades), and hunt enemies it recently lost sight of.
@MainActor
final class SoldierAI {
    let soldier: Soldier
    unowned let ctx: BattleContext
    let services: BotServices
    let follower = PathFollower()

    var targetId: Int?
    var reactionTimer: CGFloat = 0
    var lastSeenPosition: CGPoint?
    var lastSeenTime: CGFloat = -100
    var aimOffset: CGPoint = .zero
    var strafeSign: CGFloat = 1
    private var strafeTimer: CGFloat = 0
    private var thinkTimer = CGFloat.random(in: 0...AIConfig.thinkInterval)
    private var route: [CGPoint] = []
    private var routeIndex = 0

    init(soldier: Soldier, ctx: BattleContext, services: BotServices, routeIndex: Int) {
        self.soldier = soldier
        self.ctx = ctx
        self.services = services
        assignRoute(routeIndex)
    }

    func update(dt: CGFloat) {
        guard soldier.isAlive else {
            targetId = nil
            lastSeenPosition = nil
            routeIndex = 0
            follower.clear()
            return
        }
        thinkTimer -= dt
        reactionTimer -= dt
        strafeTimer -= dt
        if thinkTimer <= 0 {
            thinkTimer = AIConfig.thinkInterval * CGFloat.random(in: 0.8...1.2)
            think()
        }
        if let target = ctx.world.soldier(targetId), target.isAlive {
            fight(target, dt: dt)
        } else {
            soldier.wantsToFire = false
            if let spot = lastSeenPosition, ctx.world.time - lastSeenTime < AIConfig.huntMemory {
                hunt(spot, dt: dt)
            } else {
                advance(dt: dt)
            }
        }
    }

    /// Bots spawn again at their base after respawning: restart the route.
    func onRespawn() {
        assignRoute(Int.random(in: 0..<ctx.world.map.routeCount))
    }

    // MARK: Decisions

    private func think() {
        if strafeTimer <= 0 {
            strafeSign = Bool.random() ? 1 : -1
            strafeTimer = CGFloat.random(in: AIConfig.strafeIntervalMin...AIConfig.strafeIntervalMax)
        }
        if let enemy = services.vision.nearestVisibleEnemy(for: soldier) {
            if enemy.id != targetId { reactionTimer = AIConfig.reactionTime * CGFloat.random(in: 0.8...1.3) }
            targetId = enemy.id
            lastSeenPosition = enemy.position
            lastSeenTime = ctx.world.time
            let distance = enemy.position.distance(to: soldier.position)
            let error = AIConfig.aimErrorBase + AIConfig.aimErrorPerDistance * distance
            aimOffset = CGPoint(x: CGFloat.random(in: -error...error), y: CGFloat.random(in: -error...error))
            chooseWeapon()
            considerGrenade(at: enemy.position, distance: distance)
        } else {
            targetId = nil
            if let spot = lastSeenPosition, ctx.world.time - lastSeenTime > 0.6 {
                considerGrenade(at: spot, distance: spot.distance(to: soldier.position))
            }
            let weapon = soldier.activeWeapon
            if weapon.magazineFraction < AIConfig.reloadThreshold { services.weapons.reload(soldier) }
        }
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

    // MARK: Movement

    private func assignRoute(_ index: Int) {
        route = ctx.world.map.route(index, for: soldier.team)
        routeIndex = 0
    }

    private func advance(dt: CGFloat) {
        guard !route.isEmpty else { return }
        let waypoint = route[routeIndex]
        if soldier.position.distance(to: waypoint) < 60 {
            if routeIndex < route.count - 1 {
                routeIndex += 1
            } else {
                // Reached the enemy side: sweep another route backwards toward the middle.
                assignRoute(Int.random(in: 0..<ctx.world.map.routeCount))
                route.reverse()
            }
        }
        moveToward(route[routeIndex], dt: dt)
        soldier.aimPoint = soldier.position + soldier.moveDir * 200
    }

    private func hunt(_ spot: CGPoint, dt: CGFloat) {
        moveToward(spot, dt: dt)
        soldier.aimPoint = spot
        if soldier.position.distance(to: spot) < 40 { lastSeenPosition = nil }
    }

    func moveToward(_ point: CGPoint, dt: CGFloat) {
        soldier.moveDir = follower.direction(from: soldier.position, to: point, nav: ctx.world.nav, dt: dt) ?? .zero
    }
}

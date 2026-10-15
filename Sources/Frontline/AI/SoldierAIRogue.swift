import CoreGraphics

/// Rogue bots: they swing out to the top or bottom edge of the map, run along it past the fighting
/// and turn in behind the enemy front line, where enemies have their backs turned.
extension SoldierAI {
    func rogueMove(dt: CGFloat) {
        if rogueRoute.isEmpty { planRogueRoute() }
        // Give up on a waypoint that takes too long (blocked or unreachable).
        if !rogueRoute.isEmpty && ctx.world.time > rogueDeadline {
            rogueRoute.removeFirst()
            rogueDeadline = ctx.world.time + AIConfig.waypointTimeout
        }
        guard let goal = rogueRoute.first else {
            soldier.moveDir = .zero
            return
        }
        travelGoal = goal
        if soldier.position.distance(to: goal) < 60 {
            rogueRoute.removeFirst()
            rogueDeadline = ctx.world.time + AIConfig.waypointTimeout
            return
        }
        moveToward(goal, dt: dt)
        if soldier.moveDir.lengthSquared > 0.01 {
            soldier.aimPoint = soldier.position + soldier.moveDir * 200
        }
    }

    private func planRogueRoute() {
        let world = ctx.world
        let nav = world.nav
        let size = world.map.size
        let target = behindEnemyLines()
        let start = soldier.position
        var route: [CGPoint] = []
        if abs(target.x - start.x) > AIConfig.flankMinDistance {
            let top = Bool.random()
            let edgeY = top ? size.height - AIConfig.flankEdgeMargin : AIConfig.flankEdgeMargin
            for step in 1...3 {
                let x = start.x + (target.x - start.x) * CGFloat(step) / 4
                route.append(nav.nearestWalkable(CGPoint(x: x, y: edgeY)))
            }
        }
        route.append(nav.nearestWalkable(target))
        rogueRoute = route
        rogueDeadline = world.time + AIConfig.waypointTimeout
    }

    /// A point behind the enemies closest to our side (toward their spawn), or their spawn if none are alive.
    private func behindEnemyLines() -> CGPoint {
        let world = ctx.world
        let enemyTeam = soldier.team.opponent
        let enemySpawn = world.map.spawnZone(enemyTeam)
        let forward: CGFloat = enemySpawn.midX > soldier.position.x ? 1 : -1
        let enemies = world.soldiers.filter { $0.isAlive && $0.team == enemyTeam }
        guard !enemies.isEmpty else { return CGPoint(x: enemySpawn.midX, y: enemySpawn.midY) }
        let front = enemies.sorted { $0.position.x * forward < $1.position.x * forward }.prefix(6)
        let center = front.reduce(CGPoint.zero) { $0 + $1.position } / CGFloat(front.count)
        let behind = center + CGPoint(x: forward * AIConfig.rogueBehindDistance, y: 0)
        return behind.clamped(to: world.map.bounds.insetBy(dx: 40, dy: 40))
    }
}

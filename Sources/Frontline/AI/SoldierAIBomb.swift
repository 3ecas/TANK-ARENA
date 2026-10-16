import CoreGraphics

/// Bomb duties that override normal movement:
/// - the attacker carrying the bomb plants it as soon as it stands well inside a site with no enemy in sight;
/// - the attacking bot closest to a dropped bomb goes to pick it up;
/// - once planted, the defending bot closest to the bomb runs to it and defuses when no enemy is in sight.
extension SoldierAI {
    /// Returns true when it took control of the soldier this frame.
    func bombDuty(dt: CGFloat) -> Bool {
        let world = ctx.world
        let bomb = world.bomb
        let enemyInSight = targetId != nil
        if soldier.team == world.attackers {
            if bomb.carrierId == soldier.id {
                if !enemyInSight, let site = world.sites.first(where: { $0.contains(soldier.position) }),
                   soldier.position.distance(to: site.center) < site.radius * 0.7 {
                    holdStill(interact: true)
                    return true
                }
                // Without a squad to follow, carry the bomb to a site alone.
                guard squad == nil, !hasRecentThreat, let site = world.sites.first else { return false }
                walk(to: site.center, dt: dt)
                return true
            }
            if bomb.isDropped && !hasRecentThreat && isClosestBot(of: world.attackers, to: bomb.position) {
                walk(to: bomb.position, dt: dt)
                return true
            }
        } else if bomb.isPlanted {
            let distance = soldier.position.distance(to: bomb.position)
            if distance <= BombConfig.defuseRadius * 0.8 && !enemyInSight {
                holdStill(interact: true)
                return true
            }
            if !hasRecentThreat && isClosestBot(of: world.defenders, to: bomb.position) {
                walk(to: bomb.position, dt: dt)
                return true
            }
        }
        return false
    }

    private func holdStill(interact: Bool) {
        soldier.moveDir = .zero
        soldier.wantsToFire = false
        soldier.firePressed = false
        soldier.wantsToInteract = interact
        cover = nil
    }

    private func walk(to point: CGPoint, dt: CGFloat) {
        soldier.wantsToFire = false
        soldier.firePressed = false
        cover = nil
        travelGoal = point
        moveToward(ctx.world.nav.nearestWalkable(point), dt: dt)
        if soldier.moveDir.lengthSquared > 0.01 {
            soldier.aimPoint = soldier.position + soldier.moveDir * 200
        }
    }

    /// Whether this bot is the living bot of `team` nearest to `point` (the player is left out,
    /// so bots never wait for the player to do the job).
    private func isClosestBot(of team: Team, to point: CGPoint) -> Bool {
        let nearest = ctx.world.soldiers
            .filter { $0.isAlive && $0.team == team && !$0.isPlayer }
            .min { $0.position.distance(to: point) < $1.position.distance(to: point) }
        return nearest === soldier
    }
}

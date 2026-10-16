import CoreGraphics

/// Bomb duties that override normal movement:
/// - bomb mode: the carrier plants as soon as it stands inside a site with no enemy in sight; the nearest free
///   attacker picks up a dropped bomb;
/// - rush: the nearest free attacker near an idle station walks onto it and arms it when no enemy is in sight;
/// - both: the nearest free defender runs to an armed bomb and defuses it when no enemy is in sight.
extension SoldierAI {
    /// Returns true when it took control of the soldier this frame.
    func bombDuty(dt: CGFloat) -> Bool {
        let world = ctx.world
        let enemyInSight = targetId != nil
        for bomb in world.bombs {
            if soldier.team == world.attackers {
                if attackerDuty(bomb, enemyInSight: enemyInSight, dt: dt) { return true }
            } else if bomb.isIdle, bomb.armerId != nil {
                // An attacker is arming a station: the nearest free defender goes to stop it.
                if !hasRecentThreat && soldier.position.distance(to: bomb.position) < AIConfig.antiArmReach
                    && isClosestBot(of: world.defenders, to: bomb.position) {
                    walk(to: bomb.position, dt: dt)
                    return true
                }
            } else if bomb.isPlanted {
                let distance = soldier.position.distance(to: bomb.position)
                if distance <= BombConfig.defuseRadius && !enemyInSight {
                    holdStill(interact: true)
                    return true
                }
                if !hasRecentThreat && isClosestBot(of: world.defenders, to: bomb.position) {
                    walk(to: bomb.position, dt: dt)
                    return true
                }
            }
        }
        return false
    }

    private func attackerDuty(_ bomb: Bomb, enemyInSight: Bool, dt: CGFloat) -> Bool {
        let world = ctx.world
        switch bomb.state {
        case .carried(let id) where id == soldier.id:
            if !enemyInSight, world.sites.contains(where: { $0.contains(soldier.position) }) {
                holdStill(interact: true)
                return true
            }
            guard !hasRecentThreat else { return false }
            // Near the target (or with no squad to follow): walk straight onto the site.
            guard let site = squad?.objective ?? nearestSite() else { return false }
            guard squad == nil || soldier.position.distance(to: site.center) < site.radius * 1.8 else { return false }
            walk(to: site.center, dt: dt)
            return true
        case .dropped:
            guard !hasRecentThreat && isClosestBot(of: world.attackers, to: bomb.position) else { return false }
            walk(to: bomb.position, dt: dt)
            return true
        case .idle:
            let distance = soldier.position.distance(to: bomb.position)
            if distance <= BombConfig.armRadius * 0.8 && !enemyInSight {
                holdStill(interact: true)
                return true
            }
            // The nearest free attacker within reach goes to arm it.
            guard !hasRecentThreat, distance < AIConfig.armReach,
                  isClosestBot(of: world.attackers, to: bomb.position) else { return false }
            walk(to: bomb.position, dt: dt)
            return true
        default:
            return false
        }
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

    private func nearestSite() -> BombSite? {
        ctx.world.sites.min { $0.center.distance(to: soldier.position) < $1.center.distance(to: soldier.position) }
    }

    /// Whether this bot is the nearest free (not fighting) living bot of `team` to `point`. The player is
    /// left out, so bots never wait for the player to do the job.
    private func isClosestBot(of team: Team, to point: CGPoint) -> Bool {
        let nearest = ctx.world.soldiers
            .filter { $0.isAlive && $0.team == team && !$0.isPlayer && !$0.isEngaged }
            .min { $0.position.distance(to: point) < $1.position.distance(to: point) }
        return nearest === soldier
    }
}

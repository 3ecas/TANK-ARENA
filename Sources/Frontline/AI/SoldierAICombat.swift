import CoreGraphics

/// Fighting a known threat: pick cover according to the squad's stance, peek out to shoot,
/// duck back to reload. Falls back to strafing when no cover is close.
extension SoldierAI {
    func combat(threat: CGPoint, dt: CGFloat) {
        let target = ctx.world.soldier(targetId).flatMap { $0.isAlive ? $0 : nil }
        if let target = target, targetExposed, services.vision.isUnaware(target, of: soldier),
           ctx.world.map.hasLineOfSight(soldier.position, target.position) {
            attackExposed(target, dt: dt)
            return
        }
        soldier.aimPoint = target.map { $0.position + aimOffset } ?? predictedThreat(threat)
        shootIfPossible(target)

        let mode = coverMode()
        if needsNewCover(threat: threat) {
            cover = services.cover.find(near: soldier.position, threat: threat, mode: mode,
                                        avoid: squad?.coverSpots(excluding: self) ?? [])
            coverThreat = threat
            phase = .moving
            if cover == nil { coverRetryTimer = 0.6 }
        }
        if let spot = cover {
            useCover(spot, dt: dt)
        } else {
            strafe(around: target?.position ?? threat, dt: dt)
        }
    }

    /// The target has its back turned: leave cover and go for the kill. Close by, sneak up behind it
    /// and knife it (a backstab is lethal); further away, stop and shoot it while it is not looking.
    private func attackExposed(_ target: Soldier, dt: CGFloat) {
        cover = nil
        phase = .moving
        let distance = target.position.distance(to: soldier.position)
        let knifeReady = soldier.knifeCooldown <= 0 && !soldier.isStunned
        if distance <= AIConfig.backstabRange && knifeReady {
            soldier.aimPoint = target.position
            soldier.wantsToFire = false
            soldier.firePressed = false
            // Approach from behind the target.
            let behind = target.position - CGPoint(angle: target.facing) * (target.radius + 14)
            if distance <= GameConfig.knifeRange + target.radius {
                soldier.moveDir = .zero
                soldier.facing = (target.position - soldier.position).angle
                services.melee.swing(soldier)
            } else {
                moveToward(ctx.world.nav.nearestWalkable(behind), dt: dt)
            }
            return
        }
        // Too far to knife: hold still for accuracy and shoot (closing in a little if out of range).
        soldier.aimPoint = target.position + aimOffset
        if distance > soldier.activeWeapon.def.range * 0.9 {
            moveToward(target.position, dt: dt)
        } else {
            soldier.moveDir = .zero
        }
        shootIfPossible(target)
    }

    private func shootIfPossible(_ target: Soldier?) {
        guard let target = target else {
            soldier.wantsToFire = false
            soldier.firePressed = false
            return
        }
        let distance = target.position.distance(to: soldier.position)
        if distance <= GameConfig.knifeRange + target.radius + 4 && soldier.knifeCooldown <= 0 {
            soldier.facing = (target.position - soldier.position).angle
            services.melee.swing(soldier)
        }
        let weapon = soldier.activeWeapon
        let aimError = abs(Angle.normalize((soldier.aimPoint - soldier.position).angle - soldier.facing))
        let canShoot = reactionTimer <= 0 && distance <= weapon.def.range && !soldier.isBlind
            && aimError <= AIConfig.fireAngleTolerance + 0.25 * (aimOffset.length / Swift.max(distance, 1))
            && ctx.world.map.hasLineOfSight(soldier.position, target.position)
        soldier.wantsToFire = canShoot
        soldier.firePressed = canShoot
    }

    private func coverMode() -> CoverMode {
        if soldier.hpFraction < AIConfig.lowHealth { return .fallback }
        switch squad?.stance ?? .hold {
        case .push: return .advance
        case .retreat: return .fallback
        default: return .hold
        }
    }

    private func needsNewCover(threat: CGPoint) -> Bool {
        guard let spot = cover else { return coverRetryTimer <= 0 }
        if threat.distance(to: coverThreat) > 150 { return true }
        return !services.cover.stillCovers(spot, from: threat)
    }

    /// Run to cover, wait / reload, peek and shoot, repeat.
    private func useCover(_ spot: CoverSpot, dt: CGFloat) {
        switch phase {
        case .moving:
            moveToward(spot.position, dt: dt)
            if soldier.position.distance(to: spot.position) < 12 {
                phase = .covered
                phaseTimer = CGFloat.random(in: 0.4...1.0)
            }
        case .covered:
            holdPosition(at: spot.position, dt: dt)
            let weapon = soldier.activeWeapon
            if weapon.magazineFraction < 0.6 && !weapon.isReloading { services.weapons.reload(soldier) }
            let healthy = soldier.hpFraction >= AIConfig.lowHealth * 0.7
            if phaseTimer <= 0 && !weapon.isReloading && healthy && !soldier.isBlind {
                phase = .peeking
                phaseTimer = CGFloat.random(in: 0.9...1.7)
            }
        case .peeking:
            holdPosition(at: spot.peek, dt: dt)
            let weapon = soldier.activeWeapon
            if phaseTimer <= 0 || weapon.magazine == 0 || weapon.isReloading || soldier.isBlind {
                phase = .covered
                phaseTimer = CGFloat.random(in: 0.6...1.3)
            }
        }
    }

    private func holdPosition(at point: CGPoint, dt: CGFloat) {
        if soldier.position.distance(to: point) > 6 {
            moveToward(point, dt: dt)
        } else {
            soldier.moveDir = .zero
        }
    }

    /// No cover nearby: strafe sideways while keeping a good range.
    private func strafe(around enemyPosition: CGPoint, dt: CGFloat) {
        let toEnemy = enemyPosition - soldier.position
        let distance = toEnemy.length
        let weapon = soldier.activeWeapon
        let preferred = weapon.def.range * AIConfig.preferredRangeFraction
        let forward = distance > 1 ? toEnemy / distance : CGPoint.zero
        var approach: CGFloat = distance > preferred ? 0.7 : (distance < preferred * 0.5 ? -0.5 : 0)
        if soldier.hpFraction < AIConfig.lowHealth || squad?.stance == .retreat { approach = -0.7 }
        var desired = forward * approach + forward.perpendicular * (strafeSign * 0.8)
        let probe = soldier.position + desired.normalized * 30
        if ctx.world.map.isInsideObstacle(probe, padding: soldier.radius) {
            strafeSign = -strafeSign
            desired = forward * approach + forward.perpendicular * (strafeSign * 0.8)
        }
        soldier.moveDir = desired.lengthSquared > 0.01 ? desired.normalized : .zero
    }
}

/// Systems a bot is allowed to use to act.
@MainActor
struct BotServices {
    let vision: VisionSystem
    let weapons: WeaponSystem
    let grenades: GrenadeSystem
    let melee: MeleeSystem
    let cover: CoverFinder
    let chokepoints: Chokepoints
    let intel: TeamIntel
}

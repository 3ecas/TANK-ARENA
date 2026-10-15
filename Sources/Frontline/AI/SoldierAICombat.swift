import CoreGraphics

/// Close-combat behaviour of a bot that has a visible target.
extension SoldierAI {
    func fight(_ target: Soldier, dt: CGFloat) {
        let toTarget = target.position - soldier.position
        let distance = toTarget.length
        soldier.aimPoint = target.position + aimOffset

        if distance <= GameConfig.knifeRange + target.radius + 4 && soldier.knifeCooldown <= 0 {
            soldier.facing = toTarget.angle
            services.melee.swing(soldier)
        }

        let weapon = soldier.activeWeapon
        let aimError = abs(Angle.normalize((soldier.aimPoint - soldier.position).angle - soldier.facing))
        let canShoot = reactionTimer <= 0 && distance <= weapon.def.range && !soldier.isBlind
            && aimError <= AIConfig.fireAngleTolerance + 0.25 * (aimOffset.length / Swift.max(distance, 1))
        soldier.wantsToFire = canShoot
        soldier.firePressed = canShoot

        // Strafe sideways while closing to (or backing off from) the preferred range.
        let preferred = weapon.def.range * AIConfig.preferredRangeFraction
        let forward = distance > 1 ? toTarget / distance : CGPoint.zero
        let approach: CGFloat = distance > preferred ? 0.7 : (distance < preferred * 0.5 ? -0.5 : 0)
        let desired = forward * approach + forward.perpendicular * (strafeSign * 0.8)
        if soldier.isStunned || weapon.isReloading {
            soldier.moveDir = (forward * -0.6 + forward.perpendicular * strafeSign).normalized
        } else if desired.lengthSquared > 0.01 {
            soldier.moveDir = desired.normalized
        } else {
            soldier.moveDir = .zero
        }
        // Avoid walking into walls while strafing.
        let probe = soldier.position + soldier.moveDir * 30
        if ctx.world.map.isInsideObstacle(probe, padding: soldier.radius) {
            strafeSign = -strafeSign
            soldier.moveDir = (forward * approach + forward.perpendicular * strafeSign).normalized
        }
    }
}

/// Systems a bot is allowed to use to act.
@MainActor
struct BotServices {
    let vision: VisionSystem
    let weapons: WeaponSystem
    let grenades: GrenadeSystem
    let melee: MeleeSystem
}

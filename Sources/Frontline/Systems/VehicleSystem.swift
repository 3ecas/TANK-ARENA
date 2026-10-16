import CoreGraphics

/// Drives every vehicle from its pilot's intent (move direction, aim point, trigger): tanks turn their hull,
/// drive into walls like soldiers do and fire explosive shells from a slower-turning turret; helicopters fly
/// over everything and fire a minigun, leaving after a minute. Destroyed vehicles explode and kill their pilot.
@MainActor
final class VehicleSystem {
    unowned let ctx: BattleContext
    private let damage: DamageSystem

    init(ctx: BattleContext, damage: DamageSystem) {
        self.ctx = ctx
        self.damage = damage
    }

    func update(dt: CGFloat) {
        let world = ctx.world
        for vehicle in world.vehicles where vehicle.isAlive {
            guard let pilot = world.soldier(vehicle.pilotId), pilot.isAlive else {
                vehicle.pilotId = nil
                continue
            }
            vehicle.cooldown = Swift.max(0, vehicle.cooldown - dt)
            switch vehicle.kind {
            case .tank: driveTank(vehicle, pilot: pilot, dt: dt)
            case .helicopter: fly(vehicle, pilot: pilot, dt: dt)
            }
            pilot.position = vehicle.position
            pilot.facing = vehicle.aim
            pilot.velocity = .zero
            if pilot.wantsToFire || pilot.firePressed { fire(vehicle, pilot: pilot) }
            pilot.firePressed = false
            if vehicle.hp <= 0 {
                destroy(vehicle, pilot: pilot)
            } else if vehicle.kind == .helicopter {
                vehicle.timeLeft -= dt
                if vehicle.timeLeft <= 0 { eject(pilot, from: vehicle) }
            }
        }
    }

    // MARK: Movement

    private func driveTank(_ tank: Vehicle, pilot: Soldier, dt: CGFloat) {
        let input = pilot.moveDir
        if input.lengthSquared > 0.01 {
            let wanted = input.angle
            let diff = Angle.normalize(wanted - tank.facing)
            // Drive forward when facing roughly the right way, reverse when it's behind.
            let reversing = abs(diff) > .pi * 0.65
            let target = reversing ? wanted + .pi : wanted
            tank.facing = Angle.approach(tank.facing, target, maxStep: VehicleConfig.tankTurnRate * dt)
            let alignment = cos(Angle.normalize(target - tank.facing))
            let speed = VehicleConfig.tankSpeed * Swift.max(0, alignment) * (reversing ? -0.6 : 1)
            tank.position = tank.position + CGPoint(angle: tank.facing, length: speed * dt)
        }
        collide(tank)
        let aimAngle = (pilot.aimPoint - tank.position).angle
        tank.aim = Angle.approach(tank.aim, aimAngle, maxStep: VehicleConfig.turretTurnRate * dt)
    }

    private func fly(_ helicopter: Vehicle, pilot: Soldier, dt: CGFloat) {
        let bounds = ctx.world.map.bounds.insetBy(dx: 50, dy: 50)
        helicopter.position = (helicopter.position + pilot.moveDir.clampedLength(1) * (VehicleConfig.helicopterSpeed * dt))
            .clamped(to: bounds)
        helicopter.aim = (pilot.aimPoint - helicopter.position).angle
        helicopter.facing = Angle.approach(helicopter.facing, helicopter.aim, maxStep: 4 * dt)
    }

    /// Pushes a tank out of walls and keeps it on the map.
    private func collide(_ tank: Vehicle) {
        let r = tank.radius
        let map = ctx.world.map
        tank.position = tank.position.clamped(to: map.bounds.insetBy(dx: r, dy: r))
        let area = CGRect(x: tank.position.x - r - 2, y: tank.position.y - r - 2, width: 2 * r + 4, height: 2 * r + 4)
        for obstacle in map.obstacles(near: area) {
            let rect = obstacle.rect
            let closest = CGPoint(x: tank.position.x.clamped(rect.minX, rect.maxX), y: tank.position.y.clamped(rect.minY, rect.maxY))
            let delta = tank.position - closest
            let distance = delta.length
            if distance < r {
                tank.position = distance > 0.001 ? closest + delta * (r / distance) : tank.position + CGPoint(x: 0, y: r)
            }
        }
    }

    // MARK: Guns

    private func fire(_ vehicle: Vehicle, pilot: Soldier) {
        guard vehicle.cooldown <= 0 else { return }
        let world = ctx.world
        let muzzle = vehicle.position + CGPoint(angle: vehicle.aim, length: vehicle.radius + 14)
        switch vehicle.kind {
        case .tank:
            vehicle.cooldown = VehicleConfig.shellReload
            let end = muzzle + CGPoint(angle: vehicle.aim, length: VehicleConfig.shellRange)
            let hit = Ballistics.trace(from: muzzle, to: end, shooter: pilot, world: world)
            ctx.bus.publish(.shotFired(shooterId: pilot.id, from: muzzle, to: hit.point, weapon: .rpg, hitWall: false))
            Explosions.blast(at: hit.point - CGPoint(angle: vehicle.aim, length: 8), radius: VehicleConfig.shellBlast,
                             damage: VehicleConfig.shellDamage, vehicleDamage: VehicleConfig.shellVehicleDamage,
                             attacker: pilot, weaponName: "Tank", ctx: ctx, damage: damage)
        case .helicopter:
            vehicle.cooldown = VehicleConfig.minigunInterval
            let angle = vehicle.aim + CGFloat.random(in: -VehicleConfig.minigunSpread...VehicleConfig.minigunSpread)
            let end = muzzle + CGPoint(angle: angle, length: VehicleConfig.minigunRange)
            // Firing down from above: walls don't block it.
            let hit = Ballistics.trace(from: muzzle, to: end, shooter: pilot, world: world, ignoreWalls: true)
            ctx.bus.publish(.shotFired(shooterId: pilot.id, from: muzzle, to: hit.point, weapon: .smg, hitWall: false))
            if let target = world.vehicle(hit.vehicleId) {
                damage.apply(VehicleConfig.minigunVehicleDamage, to: target, from: pilot)
            } else if let victim = world.soldier(hit.soldierId) {
                damage.apply(VehicleConfig.minigunDamage, to: victim, from: pilot, weaponName: "Helicopter")
            }
        }
    }

    // MARK: Leaving

    private func destroy(_ vehicle: Vehicle, pilot: Soldier) {
        let attacker = ctx.world.soldier(vehicle.lastAttackerId)
        eject(pilot, from: vehicle)
        ctx.bus.publish(.vehicleDestroyed(vehicleId: vehicle.id, position: vehicle.position))
        Explosions.blast(at: vehicle.position, radius: VehicleConfig.wreckBlast, damage: VehicleConfig.wreckDamage,
                         vehicleDamage: 0, attacker: attacker, weaponName: "Explosion", ctx: ctx, damage: damage)
        damage.apply(1000, to: pilot, from: attacker, weaponName: vehicle.kind.displayName + " destroyed")
    }

    /// The pilot steps out (helicopter time up, or wreck); the vehicle is removed.
    private func eject(_ pilot: Soldier, from vehicle: Vehicle) {
        pilot.vehicleId = nil
        pilot.position = ctx.world.nav.nearestWalkable(vehicle.position)
        vehicle.pilotId = nil
    }
}

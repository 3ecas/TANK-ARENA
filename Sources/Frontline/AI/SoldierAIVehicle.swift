import CoreGraphics

/// Bots driving vehicles. Tanks roll toward the squad's objective along tank-sized paths and stop at
/// shooting distance from a target; helicopters circle their target or objective. Both fire once the gun
/// is lined up.
extension SoldierAI {
    func vehicleBrain(dt: CGFloat) {
        let world = ctx.world
        guard let vehicle = world.vehicle(of: soldier) else { return }
        let target = world.soldier(targetId).flatMap { $0.isAlive ? $0 : nil }
        // Aim and fire.
        if let target = target {
            soldier.aimPoint = target.position + aimOffset * 0.5
            let wanted = (target.position - vehicle.position).angle
            let tolerance: CGFloat = vehicle.kind == .tank ? 0.06 : 0.18
            let lined = abs(Angle.normalize(vehicle.aim - wanted)) < tolerance
            let inRange = target.position.distance(to: vehicle.position)
                <= (vehicle.kind == .tank ? VehicleConfig.shellRange : VehicleConfig.minigunRange)
            let shoot = lined && inRange && reactionTimer <= 0
            soldier.wantsToFire = shoot
            soldier.firePressed = shoot
        } else {
            soldier.wantsToFire = false
            soldier.firePressed = false
            if let threat = threatPosition, hasRecentThreat { soldier.aimPoint = predictedThreat(threat) }
        }
        // Move.
        let goal = vehicleGoal(vehicle, target: target)
        guard let destination = goal, destination.distance(to: vehicle.position) > 30 else {
            soldier.moveDir = .zero
            return
        }
        switch vehicle.kind {
        case .tank:
            soldier.moveDir = vehicleFollower.direction(from: vehicle.position, to: destination, nav: world.vehicleNav, dt: dt) ?? .zero
        case .helicopter:
            soldier.moveDir = (destination - vehicle.position).normalized
        }
        if target == nil && !hasRecentThreat && soldier.moveDir.lengthSquared > 0.01 {
            soldier.aimPoint = vehicle.position + soldier.moveDir * 300
        }
    }

    private func vehicleGoal(_ vehicle: Vehicle, target: Soldier?) -> CGPoint? {
        let world = ctx.world
        let objective = squad?.objective?.center ?? world.sites.first?.center
        switch vehicle.kind {
        case .tank:
            if let target = target {
                // Hold at gun range; close in if too far.
                let distance = target.position.distance(to: vehicle.position)
                return distance > AIConfig.tankEngageDistance ? world.vehicleNav.nearestWalkable(target.position) : nil
            }
            guard let objective = objective else { return nil }
            // Park near the objective to cover it rather than on top of it.
            let toObjective = objective - vehicle.position
            if toObjective.length < AIConfig.tankHoldDistance { return nil }
            return world.vehicleNav.nearestWalkable(objective - toObjective.normalized * (AIConfig.tankHoldDistance * 0.8))
        case .helicopter:
            let center = target?.position ?? objective ?? vehicle.position
            // Circle the point at a steady radius.
            let angle = ((vehicle.position - center).angle) + 0.6
            return center + CGPoint(angle: angle, length: AIConfig.helicopterOrbit)
        }
    }
}

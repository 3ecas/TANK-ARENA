import CoreGraphics

/// Out-of-combat movement driven by the squad: formation, support runs, pushing, holding and falling back.
extension SoldierAI {
    func groupMove(dt: CGFloat) {
        guard let squad = squad else {
            if isRogue { rogueMove(dt: dt) } else { soldier.moveDir = .zero }
            return
        }
        let goal = squadGoal(squad)
        travelGoal = goal
        guard let destination = goal, soldier.position.distance(to: destination) > 24 else {
            soldier.moveDir = .zero
            if let contact = squad.contactPoint, squad.stance != .advance {
                soldier.aimPoint = contact
            } else if let watch = watchPoint(squad: squad) {
                soldier.aimPoint = watch
            }
            return
        }
        moveToward(destination, dt: dt)
        if let contact = squad.contactPoint, squad.stance == .push || squad.stance == .hold {
            soldier.aimPoint = contact
        } else if squad.stackDoor != nil, let watch = watchPoint(squad: squad) {
            soldier.aimPoint = watch
        } else if let glance = glancePoint() {
            soldier.aimPoint = glance
        } else if soldier.moveDir.lengthSquared > 0.01 {
            soldier.aimPoint = soldier.position + soldier.moveDir * 200
        }
    }

    private func squadGoal(_ squad: Squad) -> CGPoint? {
        switch squad.stance {
        case .advance:
            let nav = ctx.world.nav
            // Stacked on a doorway: line up beside it before going in together.
            if let point = squad.stackPoint, let door = squad.stackDoor {
                if squad.leader === self { return point }
                return squad.stackSlot(for: self, point: point, door: door).map { nav.nearestWalkable($0) }
            }
            if let flank = squad.flankPoint {
                if squad.leader === self { return squad.isGathered ? flank : nil }
                return squad.formationPosition(for: self).map { nav.nearestWalkable($0) }
            }
            guard let zone = squad.objective else { return nil }
            let leaderPosition = squad.leader?.soldier.position ?? soldier.position
            // Near the zone: spread out inside it to capture and hold.
            if leaderPosition.distance(to: zone.center) < zone.radius * 1.6 {
                return squad.zoneSpot(for: self).map { nav.nearestWalkable($0) }
            }
            if squad.leader === self {
                // The leader waits for stragglers before moving on.
                return squad.isGathered ? nav.nearestWalkable(zone.center) : nil
            }
            return squad.formationPosition(for: self).map { nav.nearestWalkable($0) }
        case .support:
            return squad.supportPoint.map { approach($0, distance: AIConfig.holdDistance, squad: squad) }
        case .push:
            return squad.contactPoint.map { approach($0, distance: 220, squad: squad) }
        case .hold:
            return squad.contactPoint.map { approach($0, distance: AIConfig.holdDistance, squad: squad) }
        case .retreat:
            return squad.contactPoint.map { approach($0, distance: AIConfig.fallbackDistance, squad: squad) }
        }
    }

    /// A walkable point `distance` away from `point`, on the squad's side.
    private func approach(_ point: CGPoint, distance: CGFloat, squad: Squad) -> CGPoint {
        let from = squad.centroid ?? soldier.position
        var direction = (from - point).normalized
        if direction.lengthSquared < 0.01 { direction = CGPoint(x: soldier.team == ctx.world.attackers ? -1 : 1, y: 0) }
        // Spread members out a little so they don't stack on one spot.
        let spread = direction.perpendicular * CGFloat((soldier.id % 5) - 2) * 40
        let target = (point + direction * distance + spread).clamped(to: ctx.world.map.bounds.insetBy(dx: 30, dy: 30))
        return ctx.world.nav.nearestWalkable(target)
    }
}

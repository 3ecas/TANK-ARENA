import CoreGraphics

/// Room clearing: while advancing, a squad looks along its path for the next doorway. Usually it stacks up
/// beside the doorway, waits for everyone, holds a moment covering the opening, then goes in together.
/// Sometimes (and always when time is short or the bomb is ticking) it simply pushes through.
extension SquadCoordinator {
    func updateRoomClearing(_ squad: Squad) {
        let world = ctx.world
        let now = world.time
        squad.clearedDoors.removeAll { now - $0.1 > AIConfig.clearedMemory }
        guard squad.stance == .advance, let leader = squad.leader else {
            cancelStack(squad)
            return
        }
        let currentGoal = squad.flankPoint ?? squad.objective?.center
        if let door = squad.stackDoor, let point = squad.stackPoint {
            let leaderDistance = leader.soldier.position.distance(to: point)
            // Bomb ticking, new goal, or pulled away: drop the stack and go.
            if world.anyPlanted || currentGoal != squad.stackGoal || leaderDistance > 450 {
                cancelStack(squad)
            } else if let goAt = squad.stackGoAt {
                if now >= goAt {
                    squad.clearedDoors.append((door.position, now))
                    cancelStack(squad)
                }
            } else if let arrived = squad.stackArrived {
                // Wait for the members that are actually coming (not far stragglers or ones in their own fight).
                let ready = squad.alive.allSatisfy { member in
                    let distance = member.soldier.position.distance(to: point)
                    return distance < 160 || distance >= AIConfig.stragglerRadius || member.soldier.isEngaged
                }
                if ready || now - arrived > AIConfig.stackMaxWait {
                    let hold = AIConfig.stackHold
                    squad.stackGoAt = now + CGFloat.random(in: hold)
                }
            } else if leaderDistance < 30 {
                squad.stackArrived = now
            }
            return
        }
        guard let goal = currentGoal,
              let door = nextDoor(from: leader.soldier.position, to: goal, squad: squad) else { return }
        if shouldRush(squad) {
            squad.clearedDoors.append((door.position, now))
            return
        }
        let side: CGFloat = (leader.soldier.position - door.position).dot(door.axis) >= 0 ? 1 : -1
        squad.stackDoor = door
        squad.stackPoint = world.nav.nearestWalkable(door.position + door.axis * (side * AIConfig.stackDistance))
        squad.stackGoal = goal
        squad.stackArrived = nil
        squad.stackGoAt = nil
    }

    private func cancelStack(_ squad: Squad) {
        squad.stackDoor = nil
        squad.stackPoint = nil
        squad.stackGoal = nil
        squad.stackArrived = nil
        squad.stackGoAt = nil
    }

    /// Push straight in: the bomb is ticking, the attackers are short of time, or just sometimes.
    private func shouldRush(_ squad: Squad) -> Bool {
        let world = ctx.world
        if world.anyPlanted { return true }
        if world.mode == .bomb && squad.team == world.attackers && world.roundTimeLeft < AIConfig.rushTimeLeft { return true }
        return CGFloat.random(in: 0...1) < AIConfig.rushChance
    }

    /// The first doorway not yet cleared on the path from `start` to `goal`, if it is close enough.
    private func nextDoor(from start: CGPoint, to goal: CGPoint, squad: Squad) -> Chokepoint? {
        guard start.distance(to: goal) > 200, let path = ctx.world.nav.findPath(from: start, to: goal) else { return nil }
        var travelled: CGFloat = 0
        var previous = start
        for waypoint in path {
            let heading = (waypoint - previous).normalized
            // Only doorways the path goes through (not side doors it walks past).
            let onSegment = services.chokepoints.points.filter { door in
                Geometry.distance(from: door.position, toSegment: previous, waypoint) < 60
                    && abs(heading.dot(door.axis)) > 0.7
                    && door.position.distance(to: start) > 80
                    && !squad.clearedDoors.contains { $0.0.distance(to: door.position) < 80 }
            }
            if let door = onSegment.min(by: { $0.position.distance(to: previous) < $1.position.distance(to: previous) }) {
                return travelled + previous.distance(to: door.position) <= AIConfig.stackLookAhead ? door : nil
            }
            travelled += previous.distance(to: waypoint)
            if travelled > AIConfig.stackLookAhead { return nil }
            previous = waypoint
        }
        return nil
    }
}

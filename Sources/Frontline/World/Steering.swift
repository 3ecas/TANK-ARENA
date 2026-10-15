import CoreGraphics

/// Lightweight local pathfinding: walk straight toward the goal but slide around
/// static obstacles (structures) that block the way.
@MainActor
enum Steering {
    static func direction(from position: CGPoint, to goal: CGPoint, radius: CGFloat,
                          obstacles: [Structure]) -> CGPoint {
        let toGoal = goal - position
        let distance = toGoal.length
        guard distance > 1 else { return .zero }
        var dir = toGoal / distance
        let lookahead = Swift.min(distance, 160)

        for obstacle in obstacles where obstacle.isAlive {
            let clearance = obstacle.radius + radius + 12
            let toObstacle = obstacle.position - position
            let along = toObstacle.dot(dir)
            // Only obstacles ahead of us within the lookahead distance matter.
            guard along > 0, along < lookahead + clearance else { continue }
            if obstacle.position.distance(to: goal) < clearance { continue }
            let closest = position + dir * along
            let lateral = obstacle.position.distance(to: closest)
            guard lateral < clearance else { continue }
            // Slide around the side the goal is on.
            var side = dir.perpendicular
            if (closest - obstacle.position).dot(side) < 0 { side = -side }
            let weight = (clearance - lateral) / clearance
            dir = (dir + side * (1.5 * weight + 0.3)).normalized
        }
        return dir
    }
}

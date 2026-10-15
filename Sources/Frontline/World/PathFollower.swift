import CoreGraphics

/// Follows a path on the nav grid toward a (possibly moving) goal, replanning when needed.
@MainActor
final class PathFollower {
    private var waypoints: [CGPoint] = []
    private var plannedGoal: CGPoint?
    private var replanTimer: CGFloat = 0

    func clear() {
        waypoints = []
        plannedGoal = nil
    }

    /// Unit direction to walk in, or nil once the goal has been reached.
    func direction(from position: CGPoint, to goal: CGPoint, nav: NavGrid, dt: CGFloat) -> CGPoint? {
        replanTimer -= dt
        let goalMoved = plannedGoal.map { $0.distance(to: goal) > 48 } ?? true
        if goalMoved || replanTimer <= 0 || waypoints.isEmpty {
            plan(from: position, to: goal, nav: nav)
        }
        while waypoints.count > 1, position.distance(to: waypoints[0]) < 20 {
            waypoints.removeFirst()
        }
        guard let next = waypoints.first else { return nil }
        if waypoints.count == 1 && position.distance(to: next) < 8 { return nil }
        return (next - position).normalized
    }

    private func plan(from position: CGPoint, to goal: CGPoint, nav: NavGrid) {
        plannedGoal = goal
        replanTimer = 1.0
        waypoints = nav.findPath(from: position, to: goal) ?? [nav.nearestWalkable(goal)]
    }
}

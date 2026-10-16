import CoreGraphics

/// A team-wide push on one site: first every squad gathers at a staging point short of the site,
/// then — when most of the team is there, or time is up — everyone goes in at once (throwing grenades first).
@MainActor
final class TeamPlan {
    enum Phase {
        case gather, execute
    }

    private(set) var phase: Phase = .execute
    private(set) var target: BombSite?
    private(set) var stage: CGPoint?
    private(set) var since: CGFloat = 0

    /// Starts gathering for `target` (or clears the plan with nil).
    func reset(target: BombSite?, stage: CGPoint?, now: CGFloat) {
        self.target = target
        self.stage = stage
        since = now
        phase = stage == nil ? .execute : .gather
    }

    func execute(now: CGFloat) {
        phase = .execute
        since = now
    }

    /// Point `distance` before the end of the walking route from `start` to `goal`, or nil when it is
    /// already that close (or there is no route).
    static func stagingPoint(from start: CGPoint, to goal: CGPoint, distance: CGFloat, nav: NavGrid) -> CGPoint? {
        guard let path = nav.findPath(from: start, to: goal) else { return nil }
        let points = [start] + path
        var lengths: [CGFloat] = []
        for (a, b) in zip(points, points.dropFirst()) { lengths.append(a.distance(to: b)) }
        let total = lengths.reduce(0, +)
        guard total > distance + 150 else { return nil }
        var remaining = total - distance
        for (index, length) in lengths.enumerated() {
            if remaining <= length {
                let a = points[index], b = points[index + 1]
                return nav.nearestWalkable(a + (b - a) * (remaining / Swift.max(length, 1)))
            }
            remaining -= length
        }
        return nil
    }
}

import CoreGraphics

/// A polyline that troops follow from one base to the other.
struct LanePath {
    let points: [CGPoint]
    private let cumulative: [CGFloat]

    init(points: [CGPoint]) {
        self.points = points
        var sums: [CGFloat] = [0]
        for i in 1..<max(points.count, 1) {
            sums.append(sums[i - 1] + points[i].distance(to: points[i - 1]))
        }
        self.cumulative = sums
    }

    var totalLength: CGFloat { cumulative.last ?? 0 }

    func reversed() -> LanePath { LanePath(points: points.reversed()) }

    /// Point at a given distance along the path.
    func point(atDistance distance: CGFloat) -> CGPoint {
        guard points.count > 1 else { return points.first ?? .zero }
        let d = distance.clamped(0, totalLength)
        for i in 1..<points.count where cumulative[i] >= d {
            let segLength = cumulative[i] - cumulative[i - 1]
            let t = segLength > 0 ? (d - cumulative[i - 1]) / segLength : 0
            return points[i - 1].lerp(to: points[i], t: t)
        }
        return points[points.count - 1]
    }

    /// Distance along the path of the projection of `p` (how far it has advanced).
    func progress(of p: CGPoint) -> CGFloat {
        let (segment, t, _) = nearestSegment(to: p)
        let segLength = cumulative[segment + 1] - cumulative[segment]
        return cumulative[segment] + segLength * t
    }

    /// Distance from `p` to the path.
    func distance(from p: CGPoint) -> CGFloat {
        nearestSegment(to: p).2
    }

    /// Index of the waypoint a unit standing at `p` should walk to next.
    func nextWaypointIndex(from p: CGPoint) -> Int {
        guard points.count > 1 else { return 0 }
        let (segment, _, _) = nearestSegment(to: p)
        return min(segment + 1, points.count - 1)
    }

    private func nearestSegment(to p: CGPoint) -> (Int, CGFloat, CGFloat) {
        var best = (0, CGFloat(0), CGFloat.greatestFiniteMagnitude)
        guard points.count > 1 else { return best }
        for i in 0..<(points.count - 1) {
            let a = points[i], b = points[i + 1]
            let ab = b - a
            let lenSq = max(ab.lengthSquared, 0.0001)
            let t = ((p - a).dot(ab) / lenSq).clamped(0, 1)
            let d = p.distance(to: a + ab * t)
            if d < best.2 { best = (i, t, d) }
        }
        return best
    }
}

import CoreGraphics

/// The area a soldier can see: a view cone clipped by walls, plus a small circle of awareness around them.
enum VisibilityPolygon {
    static func compute(origin: CGPoint, facing: CGFloat, fieldOfView: CGFloat, range: CGFloat,
                        peripheral: CGFloat, map: ArenaMap, rays: Int, ignoreWalls: Bool = false) -> [CGPoint] {
        var points: [CGPoint] = []
        points.reserveCapacity(rays + 1)
        let halfFov = fieldOfView / 2
        for i in 0..<rays {
            let angle = facing - .pi + 2 * .pi * CGFloat(i) / CGFloat(rays)
            let inCone = abs(Angle.normalize(angle - facing)) <= halfFov
            let length = inCone ? range : peripheral
            let end = origin + CGPoint(angle: angle, length: length)
            let t = ignoreWalls ? 1 : (map.raycast(from: origin, to: end) ?? 1)
            points.append(origin.lerp(to: end, t: t))
        }
        return points
    }
}

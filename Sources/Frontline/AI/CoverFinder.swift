import CoreGraphics

/// A place to hide from a threat, plus a nearby spot from which the threat can be shot at.
struct CoverSpot {
    let position: CGPoint
    let peek: CGPoint
}

enum CoverMode {
    /// Pushing: prefer cover closer to the enemy.
    case advance
    /// Holding: prefer cover at a comfortable fighting distance.
    case hold
    /// Falling back: prefer cover further from the enemy.
    case fallback
}

/// Precomputes candidate cover points around every crate and building, and picks the best one
/// that hides a bot from a given threat.
@MainActor
final class CoverFinder {
    private let map: ArenaMap
    private let points: [CGPoint]
    private let clearance = GameConfig.soldierRadius + 6

    init(map: ArenaMap) {
        self.map = map
        var candidates: [CGPoint] = []
        let pad = GameConfig.soldierRadius + 8
        for obstacle in map.obstacles {
            let r = obstacle.rect.insetBy(dx: -pad, dy: -pad)
            candidates += [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                           CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.maxX, y: r.maxY)]
            for x in stride(from: r.minX + 40, to: r.maxX - 20, by: 60) {
                candidates += [CGPoint(x: x, y: r.minY), CGPoint(x: x, y: r.maxY)]
            }
            for y in stride(from: r.minY + 40, to: r.maxY - 20, by: 60) {
                candidates += [CGPoint(x: r.minX, y: y), CGPoint(x: r.maxX, y: y)]
            }
        }
        let bounds = map.bounds.insetBy(dx: pad, dy: pad)
        points = candidates.filter { bounds.contains($0) && !map.isInsideObstacle($0, padding: GameConfig.soldierRadius) }
    }

    /// Best cover near `origin` that blocks the line of sight from `threat`, avoiding spots teammates use.
    func find(near origin: CGPoint, threat: CGPoint, mode: CoverMode, avoid: [CGPoint]) -> CoverSpot? {
        let radius = mode == .fallback ? AIConfig.fallbackSearchRadius : AIConfig.coverSearchRadius
        var best: CoverSpot?
        var bestScore = CGFloat.greatestFiniteMagnitude
        for point in points {
            let travel = point.distance(to: origin)
            guard travel <= radius else { continue }
            let toThreat = point.distance(to: threat)
            guard toThreat >= 140, !map.hasLineOfSight(point, threat) else { continue }
            if avoid.contains(where: { $0.distance(to: point) < 28 }) { continue }
            var score = travel
            switch mode {
            case .advance: score += toThreat * 0.6
            case .hold: score += abs(toThreat - AIConfig.holdDistance) * 0.4
            case .fallback: score -= toThreat * 0.6
            }
            guard score < bestScore, let peek = peekPoint(from: point, threat: threat) else { continue }
            bestScore = score
            best = CoverSpot(position: point, peek: peek)
        }
        return best
    }

    /// Whether `spot` still hides from `threat`.
    func stillCovers(_ spot: CoverSpot, from threat: CGPoint) -> Bool {
        !map.hasLineOfSight(spot.position, threat)
    }

    /// A step sideways out of cover with a clear shot at the threat.
    private func peekPoint(from point: CGPoint, threat: CGPoint) -> CGPoint? {
        let side = (threat - point).normalized.perpendicular
        for offset in [CGFloat(30), -30, 50, -50, 70, -70] {
            let candidate = point + side * offset
            if !map.isInsideObstacle(candidate, padding: clearance) && map.bounds.contains(candidate)
                && map.hasLineOfSight(candidate, threat) {
                return candidate
            }
        }
        return nil
    }
}

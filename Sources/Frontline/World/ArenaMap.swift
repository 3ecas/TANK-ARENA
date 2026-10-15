import CoreGraphics

enum ObstacleKind {
    case building, crate, barrier
}

struct Obstacle {
    let rect: CGRect
    let kind: ObstacleKind
}

/// Static geometry of the arena: obstacles (solid to movement, bullets and sight), spawns and irregular barriers.
struct ArenaMap {
    let size: CGSize
    let bounds: CGRect
    let obstacles: [Obstacle]

    init() {
        size = MapConfig.size
        bounds = CGRect(origin: .zero, size: MapConfig.size)
        var list: [Obstacle] = []
        for rect in MapConfig.blueBuildings {
            list.append(Obstacle(rect: rect, kind: .building))
            list.append(Obstacle(rect: MapConfig.mirror(rect), kind: .building))
        }
        for rect in MapConfig.blueCrates {
            list.append(Obstacle(rect: rect, kind: .crate))
            list.append(Obstacle(rect: MapConfig.mirror(rect), kind: .crate))
        }
        for rect in MapConfig.irregularBarriers {
            list.append(Obstacle(rect: rect, kind: .barrier))
        }
        obstacles = list
    }

    func spawnZone(_ team: Team) -> CGRect {
        team == .red ? MapConfig.mirror(MapConfig.blueSpawn) : MapConfig.blueSpawn
    }

    func isInsideObstacle(_ p: CGPoint, padding: CGFloat = 0) -> Bool {
        obstacles.contains { $0.rect.insetBy(dx: -padding, dy: -padding).contains(p) }
    }

    /// Fraction (0...1) along a-b where the first obstacle is hit, or nil if the segment is clear.
    func raycast(from a: CGPoint, to b: CGPoint) -> CGFloat? {
        var best: CGFloat?
        for obstacle in obstacles {
            if let t = ArenaMap.segmentHit(a, b, obstacle.rect), t < (best ?? 2) { best = t }
        }
        return best
    }

    func hasLineOfSight(_ a: CGPoint, _ b: CGPoint) -> Bool {
        raycast(from: a, to: b) == nil
    }

    /// Slab test: entry fraction of segment a-b into `rect`.
    static func segmentHit(_ a: CGPoint, _ b: CGPoint, _ rect: CGRect) -> CGFloat? {
        let d = b - a
        var tMin: CGFloat = 0
        var tMax: CGFloat = 1
        if abs(d.x) < 0.0001 {
            if a.x < rect.minX || a.x > rect.maxX { return nil }
        } else {
            let t1 = (rect.minX - a.x) / d.x, t2 = (rect.maxX - a.x) / d.x
            tMin = Swift.max(tMin, Swift.min(t1, t2))
            tMax = Swift.min(tMax, Swift.max(t1, t2))
            if tMin > tMax { return nil }
        }
        if abs(d.y) < 0.0001 {
            if a.y < rect.minY || a.y > rect.maxY { return nil }
        } else {
            let t1 = (rect.minY - a.y) / d.y, t2 = (rect.maxY - a.y) / d.y
            tMin = Swift.max(tMin, Swift.min(t1, t2))
            tMax = Swift.min(tMax, Swift.max(t1, t2))
            if tMin > tMax { return nil }
        }
        return tMin
    }

    /// Random walkable point inside a team's spawn zone.
    func randomSpawnPoint(_ team: Team) -> CGPoint {
        let zone = spawnZone(team).insetBy(dx: 20, dy: 20)
        for _ in 0..<20 {
            let p = CGPoint(x: CGFloat.random(in: zone.minX...zone.maxX), y: CGFloat.random(in: zone.minY...zone.maxY))
            if !isInsideObstacle(p, padding: GameConfig.soldierRadius) { return p }
        }
        return CGPoint(x: zone.midX, y: zone.midY)
    }
}

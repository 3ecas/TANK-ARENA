import CoreGraphics

enum ObstacleKind {
    /// Office walls: block movement, bullets and sight.
    case wall
    /// Desks: low cover, same collision as walls.
    case desk
    /// Outdoor building (rush sectors 3–5).
    case building
    /// Outdoor cover: sandbags, crates, low walls.
    case crate
}

struct Obstacle {
    let rect: CGRect
    let kind: ObstacleKind
}

/// Static geometry of the arena: obstacles (solid to movement, bullets and sight), spawns and zone positions.
struct ArenaMap {
    let size: CGSize
    let bounds: CGRect
    let obstacles: [Obstacle]
    let siteSpecs: [ZoneConfig.ZoneSpec]
    let attackerSpawn: CGRect
    let defenderSpawn: CGRect
    let sectors: [RushSector]
    let outdoorStartX: CGFloat?
    let seed: UInt64
    private let index: ObstacleIndex

    init(layout: MapLayout) {
        size = layout.size
        bounds = CGRect(origin: .zero, size: layout.size)
        obstacles = layout.obstacles
        siteSpecs = layout.sites
        attackerSpawn = layout.attackerSpawn
        defenderSpawn = layout.defenderSpawn
        sectors = layout.sectors
        outdoorStartX = layout.outdoorStartX
        seed = layout.seed
        index = ObstacleIndex(obstacles: layout.obstacles, size: layout.size)
    }

    /// Every spawn pad (all rush sectors).
    var allSpawns: [CGRect] {
        sectors.isEmpty ? [attackerSpawn, defenderSpawn] : sectors.flatMap { [$0.attackerSpawn, $0.defenderSpawn] }
    }

    /// Every site (all rush sectors).
    var allSites: [ZoneConfig.ZoneSpec] {
        sectors.isEmpty ? siteSpecs : sectors.flatMap { $0.sites }
    }

    /// Obstacles that may overlap `rect`.
    func obstacles(near rect: CGRect) -> [Obstacle] {
        index.candidates(in: rect).map { obstacles[$0] }
    }

    func isInsideObstacle(_ p: CGPoint, padding: CGFloat = 0) -> Bool {
        let probe = CGRect(x: p.x - padding, y: p.y - padding, width: padding * 2, height: padding * 2)
        return index.candidates(in: probe).contains { obstacles[$0].rect.insetBy(dx: -padding, dy: -padding).contains(p) }
    }

    /// Fraction (0...1) along a-b where the first obstacle is hit, or nil if the segment is clear.
    func raycast(from a: CGPoint, to b: CGPoint) -> CGFloat? {
        var best: CGFloat?
        let box = CGRect(x: Swift.min(a.x, b.x), y: Swift.min(a.y, b.y), width: abs(b.x - a.x), height: abs(b.y - a.y))
        for i in index.candidates(in: box) {
            let rect = obstacles[i].rect
            guard rect.intersects(box.insetBy(dx: -1, dy: -1)) else { continue }
            if let t = ArenaMap.segmentHit(a, b, rect), t < (best ?? 2) { best = t }
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

    /// Random walkable point inside a spawn rectangle.
    func randomPoint(in spawn: CGRect) -> CGPoint {
        let zone = spawn.insetBy(dx: 20, dy: 20)
        for _ in 0..<20 {
            let p = CGPoint(x: CGFloat.random(in: zone.minX...zone.maxX), y: CGFloat.random(in: zone.minY...zone.maxY))
            if !isInsideObstacle(p, padding: GameConfig.soldierRadius) { return p }
        }
        return CGPoint(x: zone.midX, y: zone.midY)
    }
}

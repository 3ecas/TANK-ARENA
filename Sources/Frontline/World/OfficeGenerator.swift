import CoreGraphics

/// Generates a simple office floor: a grid of rooms, every room reachable (random spanning tree of
/// doorways plus some extra doors), the rooms under each spawn merged into one big room, and a few desks.
struct OfficeGenerator {
    let size: CGSize
    let spawns: [CGRect]
    let sites: [CGPoint]
    private var rng: SeededRandom

    init(seed: UInt64, size: CGSize, spawns: [CGRect], sites: [CGPoint]) {
        self.size = size
        self.spawns = spawns
        self.sites = sites
        rng = SeededRandom(seed: seed)
    }

    private var roomSize: CGSize {
        CGSize(width: size.width / CGFloat(OfficeConfig.columns), height: size.height / CGFloat(OfficeConfig.rows))
    }

    private func roomRect(_ x: Int, _ y: Int) -> CGRect {
        CGRect(x: CGFloat(x) * roomSize.width, y: CGFloat(y) * roomSize.height, width: roomSize.width, height: roomSize.height)
    }

    /// Rooms touched by a spawn rectangle are merged into one open area.
    private func spawnGroup(_ x: Int, _ y: Int) -> Int? {
        spawns.firstIndex { $0.intersects(roomRect(x, y).insetBy(dx: 10, dy: 10)) }
    }

    mutating func generate() -> [Obstacle] {
        var walls = outerWalls()
        let doors = pickDoors()
        let t = OfficeConfig.wallThickness
        // Vertical walls between (x, y) and (x + 1, y).
        for y in 0..<OfficeConfig.rows {
            for x in 0..<(OfficeConfig.columns - 1) {
                let room = roomRect(x, y)
                let wall = CGRect(x: room.maxX - t / 2, y: room.minY, width: t, height: room.height)
                walls += segment(wall, vertical: true, edge: Edge(x: x, y: y, horizontal: true), doors: doors)
            }
        }
        // Horizontal walls between (x, y) and (x, y + 1).
        for y in 0..<(OfficeConfig.rows - 1) {
            for x in 0..<OfficeConfig.columns {
                let room = roomRect(x, y)
                let wall = CGRect(x: room.minX, y: room.maxY - t / 2, width: room.width, height: t)
                walls += segment(wall, vertical: false, edge: Edge(x: x, y: y, horizontal: false), doors: doors)
            }
        }
        return walls.map { Obstacle(rect: $0, kind: .wall) } + desks().map { Obstacle(rect: $0, kind: .desk) }
    }

    private func outerWalls() -> [CGRect] {
        let o = OfficeConfig.outerWall
        return [CGRect(x: 0, y: 0, width: size.width, height: o),
                CGRect(x: 0, y: size.height - o, width: size.width, height: o),
                CGRect(x: 0, y: 0, width: o, height: size.height),
                CGRect(x: size.width - o, y: 0, width: o, height: size.height)]
    }

    /// A wall between two rooms: removed inside a spawn area, split around a doorway, or solid.
    private mutating func segment(_ wall: CGRect, vertical: Bool, edge: Edge, doors: Set<Edge>) -> [CGRect] {
        let a = spawnGroup(edge.x, edge.y)
        let b = edge.horizontal ? spawnGroup(edge.x + 1, edge.y) : spawnGroup(edge.x, edge.y + 1)
        if let a = a, a == b { return [] }
        guard doors.contains(edge) else { return [wall] }
        let length = vertical ? wall.height : wall.width
        let door = OfficeConfig.doorWidth
        let start = 60 + rng.next() * (length - door - 120)
        if vertical {
            return [CGRect(x: wall.minX, y: wall.minY, width: wall.width, height: start),
                    CGRect(x: wall.minX, y: wall.minY + start + door, width: wall.width, height: length - start - door)]
        }
        return [CGRect(x: wall.minX, y: wall.minY, width: start, height: wall.height),
                CGRect(x: wall.minX + start + door, y: wall.minY, width: length - start - door, height: wall.height)]
    }

    /// Doorways: a random spanning tree over the rooms (so every room is reachable) plus extra random doors.
    private mutating func pickDoors() -> Set<Edge> {
        let columns = OfficeConfig.columns, rows = OfficeConfig.rows
        var visited = Set<Int>([0])
        var stack = [0]
        var doors = Set<Edge>()
        while let current = stack.last {
            let x = current % columns, y = current / columns
            var options: [(Int, Edge)] = []
            if x + 1 < columns { options.append((current + 1, Edge(x: x, y: y, horizontal: true))) }
            if x > 0 { options.append((current - 1, Edge(x: x - 1, y: y, horizontal: true))) }
            if y + 1 < rows { options.append((current + columns, Edge(x: x, y: y, horizontal: false))) }
            if y > 0 { options.append((current - columns, Edge(x: x, y: y - 1, horizontal: false))) }
            let open = options.filter { !visited.contains($0.0) }
            guard !open.isEmpty else {
                stack.removeLast()
                continue
            }
            let pick = open[Swift.min(open.count - 1, Int(rng.next() * CGFloat(open.count)))]
            visited.insert(pick.0)
            doors.insert(pick.1)
            stack.append(pick.0)
        }
        for y in 0..<rows {
            for x in 0..<columns {
                if x + 1 < columns && rng.next() < OfficeConfig.extraDoorChance { doors.insert(Edge(x: x, y: y, horizontal: true)) }
                if y + 1 < rows && rng.next() < OfficeConfig.extraDoorChance { doors.insert(Edge(x: x, y: y, horizontal: false)) }
            }
        }
        return doors
    }

    /// A few desks per room, away from the walls, not in spawn rooms and not on a site centre.
    private mutating func desks() -> [CGRect] {
        var result: [CGRect] = []
        let margin = OfficeConfig.deskMargin
        for y in 0..<OfficeConfig.rows {
            for x in 0..<OfficeConfig.columns where spawnGroup(x, y) == nil {
                let area = roomRect(x, y).insetBy(dx: margin, dy: margin)
                let range = OfficeConfig.desksPerRoom
                let count = range.lowerBound + Int(rng.next() * CGFloat(range.upperBound - range.lowerBound + 1))
                var placed: [CGRect] = []
                for _ in 0..<(count * 6) where placed.count < count {
                    let sizes = OfficeConfig.deskSizes
                    let deskSize = sizes[Swift.min(sizes.count - 1, Int(rng.next() * CGFloat(sizes.count)))]
                    guard area.width > deskSize.width, area.height > deskSize.height else { continue }
                    let desk = CGRect(x: area.minX + rng.next() * (area.width - deskSize.width),
                                      y: area.minY + rng.next() * (area.height - deskSize.height),
                                      width: deskSize.width, height: deskSize.height)
                    let clearOfSites = sites.allSatisfy { site in
                        CGPoint(x: desk.midX, y: desk.midY).distance(to: site) > 70 && !desk.contains(site)
                    }
                    let clearOfDesks = placed.allSatisfy { !$0.insetBy(dx: -60, dy: -60).intersects(desk) }
                    if clearOfSites && clearOfDesks { placed.append(desk) }
                }
                result += placed
            }
        }
        return result
    }

    private struct Edge: Hashable {
        let x: Int
        let y: Int
        /// true: wall between (x, y) and (x + 1, y); false: between (x, y) and (x, y + 1).
        let horizontal: Bool
    }
}

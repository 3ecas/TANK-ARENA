import CoreGraphics

enum MapKind {
    case compound, caves

    var displayName: String {
        switch self {
        case .compound: return "Compound"
        case .caves: return "Caves"
        }
    }
}

/// Everything that describes one map: size, solid obstacles, the two spawns and the two bomb sites.
struct MapLayout {
    let kind: MapKind
    let size: CGSize
    let obstacles: [Obstacle]
    let attackerSpawn: CGRect
    let defenderSpawn: CGRect
    let sites: [ZoneConfig.ZoneSpec]
    /// Rock grid of a cave map (used for painting), nil for the compound.
    let cave: CaveGrid?
    let seed: UInt64

    static func make(_ kind: MapKind) -> MapLayout {
        switch kind {
        case .compound: return compound()
        case .caves: return caves(seed: UInt64.random(in: 1...UInt64(UInt32.max))) ?? compound()
        }
    }

    /// The hand-made indoor compound: walls, rooms, corridors and crates.
    static func compound() -> MapLayout {
        let list = MapConfig.walls.map { Obstacle(rect: $0, kind: .wall) }
            + MapConfig.crates.map { Obstacle(rect: $0, kind: .crate) }
        return MapLayout(kind: .compound, size: MapConfig.size, obstacles: list, attackerSpawn: MapConfig.attackerSpawn,
                         defenderSpawn: MapConfig.defenderSpawn, sites: MapConfig.sites, cave: nil, seed: 0)
    }

    /// A freshly generated cave system with the same spawns and sites. Seeds with anything cut off are skipped.
    static func caves(seed: UInt64) -> MapLayout? {
        let spawns = [MapConfig.attackerSpawn, MapConfig.defenderSpawn]
        for attempt in 0..<UInt64(CaveConfig.maxAttempts) {
            let currentSeed = seed &+ attempt &* 7919
            var generator = CaveGenerator(seed: currentSeed, size: MapConfig.size, spawns: spawns,
                                          zones: MapConfig.sites.map { $0.center })
            let grid = generator.generate()
            let obstacles = grid.rectangles().map { Obstacle(rect: $0, kind: .rock) }
            let layout = MapLayout(kind: .caves, size: MapConfig.size, obstacles: obstacles,
                                   attackerSpawn: MapConfig.attackerSpawn, defenderSpawn: MapConfig.defenderSpawn,
                                   sites: MapConfig.sites, cave: grid, seed: currentSeed)
            if layout.isFullyConnected() { return layout }
        }
        return nil
    }

    /// Soldiers can walk from the attacker spawn to the defender spawn and both sites.
    func isFullyConnected() -> Bool {
        var nav = NavGrid(size: size, cellSize: GameConfig.navCellSize)
        nav.rebuild(rects: obstacles.map { $0.rect }, padding: GameConfig.navPadding)
        let reachable = nav.reachableCells(from: CGPoint(x: attackerSpawn.midX, y: attackerSpawn.midY))
        let goals = sites.map { $0.center } + [CGPoint(x: defenderSpawn.midX, y: defenderSpawn.midY)]
        return goals.allSatisfy { reachable(nav.nearestWalkable($0)) }
    }
}

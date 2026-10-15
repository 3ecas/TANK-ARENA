import CoreGraphics

enum MapKind {
    case city, caves

    var displayName: String {
        switch self {
        case .city: return "City"
        case .caves: return "Caves"
        }
    }
}

/// Everything that describes one map: size, solid obstacles, and the Breakthrough sectors.
struct MapLayout {
    let kind: MapKind
    let size: CGSize
    let obstacles: [Obstacle]
    let sectors: [BreakthroughConfig.SectorSpec]
    /// Rock grid of a cave map (used for painting), nil for the city.
    let cave: CaveGrid?
    let seed: UInt64

    static func make(_ kind: MapKind) -> MapLayout {
        switch kind {
        case .city: return city()
        case .caves: return caves(seed: UInt64.random(in: 1...UInt64(UInt32.max))) ?? city()
        }
    }

    /// The hand-made city: irregular buildings, crates and wrecks.
    static func city() -> MapLayout {
        let list = MapConfig.buildings.map { Obstacle(rect: $0, kind: .building) }
            + MapConfig.crates.map { Obstacle(rect: $0, kind: .crate) }
            + MapConfig.barriers.map { Obstacle(rect: $0, kind: .barrier) }
        return MapLayout(kind: .city, size: BreakthroughConfig.mapSize, obstacles: list,
                         sectors: BreakthroughConfig.sectors, cave: nil, seed: 0)
    }

    /// A freshly generated cave system. Seeds where a zone or spawn is cut off are skipped.
    static func caves(seed: UInt64) -> MapLayout? {
        let sectors = BreakthroughConfig.sectors
        let spawns = sectors.map { $0.attackerSpawn } + sectors.map { $0.defenderSpawn }
        let zones = sectors.flatMap { $0.zones.map { $0.center } }
        for attempt in 0..<UInt64(CaveConfig.maxAttempts) {
            let currentSeed = seed &+ attempt &* 7919
            var generator = CaveGenerator(seed: currentSeed, size: BreakthroughConfig.mapSize, spawns: spawns, zones: zones)
            let grid = generator.generate()
            let obstacles = grid.rectangles().map { Obstacle(rect: $0, kind: .rock) }
            let layout = MapLayout(kind: .caves, size: BreakthroughConfig.mapSize, obstacles: obstacles,
                                   sectors: sectors, cave: grid, seed: currentSeed)
            if layout.isFullyConnected() { return layout }
        }
        return nil
    }

    /// Soldiers can walk from the first attacker spawn to every spawn and every zone.
    func isFullyConnected() -> Bool {
        var nav = NavGrid(size: size, cellSize: GameConfig.navCellSize)
        nav.rebuild(rects: obstacles.map { $0.rect }, padding: GameConfig.navPadding)
        guard let first = sectors.first else { return false }
        let reachable = nav.reachableCells(from: CGPoint(x: first.attackerSpawn.midX, y: first.attackerSpawn.midY))
        var goals: [CGPoint] = []
        for sector in sectors {
            goals += sector.zones.map { $0.center }
            goals += [sector.attackerSpawn, sector.defenderSpawn].map { CGPoint(x: $0.midX, y: $0.midY) }
        }
        return goals.allSatisfy { reachable(nav.nearestWalkable($0)) }
    }
}

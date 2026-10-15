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

/// Everything that describes one map: size, solid obstacles, spawns and control zones.
struct MapLayout {
    let kind: MapKind
    let size: CGSize
    let obstacles: [Obstacle]
    let blueSpawn: CGRect
    let redSpawn: CGRect
    let zones: [ZoneConfig.ZoneSpec]
    /// Rock grid of a cave map (used for painting), nil for the city.
    let cave: CaveGrid?
    let seed: UInt64

    static func make(_ kind: MapKind) -> MapLayout {
        switch kind {
        case .city: return city()
        case .caves: return caves(seed: UInt64.random(in: 1...UInt64(UInt32.max))) ?? city()
        }
    }

    /// The hand-made city: mirrored buildings and crates plus unmirrored barriers.
    static func city() -> MapLayout {
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
        return MapLayout(kind: .city, size: MapConfig.size, obstacles: list, blueSpawn: MapConfig.blueSpawn,
                         redSpawn: MapConfig.mirror(MapConfig.blueSpawn), zones: ZoneConfig.zones, cave: nil, seed: 0)
    }

    /// A freshly generated cave system. Seeds whose zones or spawns are not all connected are skipped.
    static func caves(seed: UInt64) -> MapLayout? {
        let blue = MapConfig.blueSpawn
        let red = MapConfig.mirror(MapConfig.blueSpawn)
        for attempt in 0..<UInt64(CaveConfig.maxAttempts) {
            let currentSeed = seed &+ attempt &* 7919
            var generator = CaveGenerator(seed: currentSeed, size: MapConfig.size, blueSpawn: blue, redSpawn: red,
                                          zones: CaveConfig.zones.map { $0.center })
            let grid = generator.generate()
            let obstacles = grid.rectangles().map { Obstacle(rect: $0, kind: .rock) }
            let layout = MapLayout(kind: .caves, size: MapConfig.size, obstacles: obstacles, blueSpawn: blue,
                                   redSpawn: red, zones: CaveConfig.zones, cave: grid, seed: currentSeed)
            if layout.isFullyConnected() { return layout }
        }
        return nil
    }

    /// Soldiers can walk from the blue spawn to the red spawn and to every zone.
    func isFullyConnected() -> Bool {
        var nav = NavGrid(size: size, cellSize: GameConfig.navCellSize)
        nav.rebuild(rects: obstacles.map { $0.rect }, padding: GameConfig.navPadding)
        let start = nav.nearestWalkable(CGPoint(x: blueSpawn.midX, y: blueSpawn.midY))
        let goals = [CGPoint(x: redSpawn.midX, y: redSpawn.midY)] + zones.map { $0.center }
        return goals.allSatisfy { nav.findPath(from: start, to: $0) != nil }
    }
}

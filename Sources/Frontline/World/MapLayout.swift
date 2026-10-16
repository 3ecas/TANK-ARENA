import CoreGraphics

/// One generated office floor: size, solid obstacles, the two spawns and the two sites.
struct MapLayout {
    let size: CGSize
    let obstacles: [Obstacle]
    let attackerSpawn: CGRect
    let defenderSpawn: CGRect
    let sites: [ZoneConfig.ZoneSpec]
    let seed: UInt64

    /// A new office for the mode. Layouts with anything unreachable are thrown away; after
    /// `maxAttempts` the last one is used anyway (its spawns and sites are always open floor).
    static func office(for mode: GameMode) -> MapLayout {
        let style = mode.style
        let seed = UInt64.random(in: 1...UInt64(UInt32.max))
        var layout: MapLayout?
        for attempt in 0..<UInt64(maxAttempts) {
            let currentSeed = seed &+ attempt &* 7919
            var generator = OfficeGenerator(seed: currentSeed, style: style)
            let obstacles = generator.generate()
            let candidate = MapLayout(size: style.size, obstacles: obstacles, attackerSpawn: style.attackerSpawn,
                                      defenderSpawn: style.defenderSpawn, sites: generator.sites, seed: currentSeed)
            layout = candidate
            if candidate.isFullyConnected() { return candidate }
        }
        return layout!
    }

    private static let maxAttempts = 12

    /// Soldiers can walk from the attacker spawn to the defender spawn and both sites.
    func isFullyConnected() -> Bool {
        var nav = NavGrid(size: size, cellSize: GameConfig.navCellSize)
        nav.rebuild(rects: obstacles.map { $0.rect }, padding: GameConfig.navPadding)
        let reachable = nav.reachableCells(from: CGPoint(x: attackerSpawn.midX, y: attackerSpawn.midY))
        let goals = sites.map { $0.center } + [CGPoint(x: defenderSpawn.midX, y: defenderSpawn.midY)]
        return goals.allSatisfy { reachable(nav.nearestWalkable($0)) }
    }
}

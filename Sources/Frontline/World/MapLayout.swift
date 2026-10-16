import CoreGraphics

/// The map: size, solid obstacles, the two spawns and the two sites.
struct MapLayout {
    let size: CGSize
    let obstacles: [Obstacle]
    let attackerSpawn: CGRect
    let defenderSpawn: CGRect
    let sites: [ZoneConfig.ZoneSpec]
    /// Identifies the layout for texture caching (the office is fixed).
    let seed: UInt64

    /// The hand-made office (see MapConfig).
    static func office() -> MapLayout {
        let obstacles = MapConfig.walls.map { Obstacle(rect: $0, kind: .wall) }
            + MapConfig.desks.map { Obstacle(rect: $0, kind: .desk) }
        return MapLayout(size: MapConfig.size, obstacles: obstacles, attackerSpawn: MapConfig.attackerSpawn,
                         defenderSpawn: MapConfig.defenderSpawn, sites: MapConfig.sites, seed: 1)
    }
}

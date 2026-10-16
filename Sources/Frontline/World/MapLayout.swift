import CoreGraphics

/// A map: size, solid obstacles, spawns, sites and (rush) its sectors.
struct MapLayout {
    let size: CGSize
    let obstacles: [Obstacle]
    let attackerSpawn: CGRect
    let defenderSpawn: CGRect
    let sites: [ZoneConfig.ZoneSpec]
    /// Rush sectors in order (empty in bomb mode).
    let sectors: [RushSector]
    /// x where indoor floor turns into open ground (nil = all indoor).
    let outdoorStartX: CGFloat?
    /// Identifies the layout for texture caching.
    let seed: UInt64

    static func make(for mode: GameMode) -> MapLayout {
        mode == .rush ? rush() : office()
    }

    /// The hand-made office (bomb mode, see MapConfig).
    static func office() -> MapLayout {
        let obstacles = MapConfig.walls.map { Obstacle(rect: $0, kind: .wall) }
            + MapConfig.desks.map { Obstacle(rect: $0, kind: .desk) }
        return MapLayout(size: MapConfig.size, obstacles: obstacles, attackerSpawn: MapConfig.attackerSpawn,
                         defenderSpawn: MapConfig.defenderSpawn, sites: MapConfig.sites, sectors: [],
                         outdoorStartX: nil, seed: 1)
    }

    /// The five-sector rush map (see RushMapConfig).
    static func rush() -> MapLayout {
        let obstacles = RushMapConfig.walls.map { Obstacle(rect: $0, kind: .wall) }
            + RushMapConfig.desks.map { Obstacle(rect: $0, kind: .desk) }
            + RushMapConfig.buildings.map { Obstacle(rect: $0, kind: .building) }
            + RushMapConfig.cover.map { Obstacle(rect: $0, kind: .crate) }
        let first = RushMapConfig.sectors[0]
        return MapLayout(size: RushMapConfig.size, obstacles: obstacles, attackerSpawn: first.attackerSpawn,
                         defenderSpawn: first.defenderSpawn, sites: first.sites, sectors: RushMapConfig.sectors,
                         outdoorStartX: RushMapConfig.outdoorStartX, seed: 2)
    }
}

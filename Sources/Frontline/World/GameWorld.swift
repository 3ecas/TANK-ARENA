import CoreGraphics

/// Container for all live game state. Holds data only; systems implement behaviour.
@MainActor
final class GameWorld {
    let map = MapLayout()
    let city: CityLayout
    /// Walkability for click-to-move pathfinding (rebuilt when structures fall).
    var nav: NavGrid
    let grid: SpatialGrid
    private(set) var entities: [Entity] = []
    private var byId: [Int: Entity] = [:]
    private(set) var heroes: [Hero] = []
    private(set) var structures: [Structure] = []
    var projectiles: [Projectile] = []
    var strikes: [StrikeZone] = []
    var zones: [AreaZone] = []
    var capturePoints: [CapturePoint] = []
    /// Lanes where a team has destroyed the enemy barracks (team -> lanes).
    var barracksDestroyed: [Team: Set<Lane>] = [.blue: [], .red: []]
    var time: CGFloat = 0
    var winner: Team?
    private var nextId = 1

    init() {
        grid = SpatialGrid(worldSize: MapConfig.size, cellSize: GameConfig.spatialCellSize)
        city = CityGenerator.generate(map: MapLayout())
        nav = NavGrid(worldSize: MapConfig.size, cellSize: CityConfig.navCellSize)
    }

    /// Recomputes the nav grid from buildings and living structures.
    func rebuildNavigation() {
        let circles = structures.filter { $0.isAlive && !$0.isRemoved }.map { ($0.position, $0.radius) }
        nav.rebuild(rects: city.buildings.map { $0.rect }, circles: circles, padding: CityConfig.navPadding)
    }

    var player: Hero? { heroes.first { $0.isPlayer } }

    func makeId() -> Int {
        defer { nextId += 1 }
        return nextId
    }

    func add(_ entity: Entity) {
        entities.append(entity)
        byId[entity.id] = entity
        if let hero = entity as? Hero { heroes.append(hero) }
        if let structure = entity as? Structure { structures.append(structure) }
    }

    func entity(_ id: Int?) -> Entity? {
        guard let id = id else { return nil }
        return byId[id]
    }

    func hero(_ id: Int?) -> Hero? {
        entity(id) as? Hero
    }

    func addProjectile(_ projectile: Projectile) { projectiles.append(projectile) }
    func addStrike(_ strike: StrikeZone) { strikes.append(strike) }
    func addZone(_ zone: AreaZone) { zones.append(zone) }

    /// Removes entities flagged for removal plus finished projectiles / strikes / zones.
    func purge() {
        if entities.contains(where: { $0.isRemoved }) {
            for entity in entities where entity.isRemoved { byId[entity.id] = nil }
            entities.removeAll { $0.isRemoved }
            structures.removeAll { $0.isRemoved }
        }
        projectiles.removeAll { $0.isDone }
        strikes.removeAll { $0.isDone }
        zones.removeAll { $0.isDone }
    }

    func heroes(of team: Team) -> [Hero] {
        heroes.filter { $0.team == team }
    }

    func capturePoint(_ kind: CapturePointKind) -> CapturePoint? {
        capturePoints.first { $0.kind == kind }
    }
}

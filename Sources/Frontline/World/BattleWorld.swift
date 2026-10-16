import CoreGraphics

/// All live state of one battle. Holds data only; systems implement behaviour.
@MainActor
final class BattleWorld {
    let map: ArenaMap
    private(set) var nav: NavGrid
    /// Pathfinding for tanks (obstacles padded by a tank's size).
    private(set) var vehicleNav: NavGrid
    private(set) var soldiers: [Soldier] = []
    private var byId: [Int: Soldier] = [:]
    var grenades: [Grenade] = []
    var vehicles: [Vehicle] = []
    var boxes: [SupplyBox] = []
    /// Sites being fought over (rush: the current sector's).
    private(set) var sites: [BombSite]
    let mode: GameMode
    /// Bomb mode: the single carried bomb. Rush: one station per site of the current sector.
    private(set) var bombs: [Bomb]
    /// Rush: index of the current sector; `sectorVersion` changes whenever the sites / bombs are replaced.
    private(set) var sector = 0
    private(set) var sectorVersion = 0
    var time: CGFloat = 0
    /// The team carrying the bomb (the other team defends the sites).
    let attackers: Team
    var defenders: Team { attackers.opponent }
    /// Bomb mode: seconds left before the bomb must be planted.
    var roundTimeLeft = BombConfig.roundTime
    /// Rush: attacker respawns left.
    var tickets = BombConfig.rushTickets
    /// Set when the battle is over.
    var result: MatchResult?
    private var nextId = 1

    init(layout: MapLayout, mode: GameMode, attackers: Team) {
        let arena = ArenaMap(layout: layout)
        var grid = NavGrid(size: arena.size, cellSize: GameConfig.navCellSize)
        grid.rebuild(rects: arena.obstacles.map { $0.rect }, padding: GameConfig.navPadding)
        var tankGrid = NavGrid(size: arena.size, cellSize: GameConfig.navCellSize)
        tankGrid.rebuild(rects: arena.obstacles.map { $0.rect }, padding: VehicleConfig.tankRadius + 6)
        map = arena
        nav = grid
        vehicleNav = tankGrid
        self.attackers = attackers
        self.mode = mode
        let siteList = arena.siteSpecs.map { BombSite(name: $0.name, center: $0.center, radius: ZoneConfig.radius) }
        sites = siteList
        switch mode {
        case .bomb: bombs = [Bomb(carrier: -1, position: .zero)]
        case .rush: bombs = siteList.map { Bomb(station: $0) }
        }
    }

    /// The bomb-mode bomb (the first station in rush).
    var bomb: Bomb { bombs[0] }

    var anyPlanted: Bool { bombs.contains { $0.isPlanted } }

    /// Rush: the station on a site.
    func station(at site: BombSite) -> Bomb? {
        bombs.first { $0.site === site }
    }

    /// Rush: the sector being fought over.
    var currentSector: RushSector? {
        map.sectors.isEmpty ? nil : map.sectors[Swift.min(sector, map.sectors.count - 1)]
    }

    var isLastSector: Bool { sector >= map.sectors.count - 1 }

    /// Tanks and helicopters can be called in (rush, open sectors only).
    var vehiclesAllowed: Bool { currentSector?.allowsVehicles ?? false }

    /// Rush: moves the fight to the next sector with fresh stations.
    func advanceSector() {
        guard !isLastSector else { return }
        sector += 1
        sectorVersion += 1
        let specs = currentSector?.sites ?? []
        sites = specs.map { BombSite(name: $0.name, center: $0.center, radius: ZoneConfig.radius) }
        bombs = sites.map { Bomb(station: $0) }
    }

    func vehicle(_ id: Int?) -> Vehicle? {
        guard let id = id else { return nil }
        return vehicles.first { $0.id == id }
    }

    /// The vehicle a soldier is riding, if any.
    func vehicle(of soldier: Soldier) -> Vehicle? {
        vehicle(soldier.vehicleId)
    }

    /// Where a team spawns (rush: depends on the sector).
    func spawnZone(_ team: Team) -> CGRect {
        if let sector = currentSector { return team == attackers ? sector.attackerSpawn : sector.defenderSpawn }
        return team == attackers ? map.attackerSpawn : map.defenderSpawn
    }

    func randomSpawnPoint(_ team: Team) -> CGPoint {
        map.randomPoint(in: spawnZone(team))
    }

    var player: Soldier? { soldiers.first { $0.isPlayer } }

    func makeId() -> Int {
        defer { nextId += 1 }
        return nextId
    }

    func add(_ soldier: Soldier) {
        soldiers.append(soldier)
        byId[soldier.id] = soldier
    }

    func soldier(_ id: Int?) -> Soldier? {
        guard let id = id else { return nil }
        return byId[id]
    }

    func soldiers(of team: Team) -> [Soldier] {
        soldiers.filter { $0.team == team }
    }

    func aliveCount(_ team: Team) -> Int {
        soldiers.filter { $0.team == team && $0.isAlive }.count
    }

    /// Soldiers still in the fight (alive or waiting to respawn).
    func remainingCount(_ team: Team) -> Int {
        soldiers.filter { $0.team == team && !$0.isEliminated }.count
    }

    func purge() {
        grenades.removeAll { $0.isDone }
        vehicles.removeAll { !$0.isAlive }
        boxes.removeAll { $0.timeLeft <= 0 }
    }
}

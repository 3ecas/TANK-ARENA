import CoreGraphics

/// All live state of one battle. Holds data only; systems implement behaviour.
@MainActor
final class BattleWorld {
    let map: ArenaMap
    private(set) var nav: NavGrid
    private(set) var soldiers: [Soldier] = []
    private var byId: [Int: Soldier] = [:]
    var grenades: [Grenade] = []
    let sites: [BombSite]
    let mode: GameMode
    /// Bomb mode: the single carried bomb. Rush: one station per site.
    let bombs: [Bomb]
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
        map = arena
        nav = grid
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

    /// Where a team starts the round.
    func spawnZone(_ team: Team) -> CGRect {
        team == attackers ? map.attackerSpawn : map.defenderSpawn
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
    }
}

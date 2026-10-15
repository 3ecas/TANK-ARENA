import CoreGraphics

/// All live state of one battle. Holds data only; systems implement behaviour.
@MainActor
final class BattleWorld {
    let map: ArenaMap
    private(set) var nav: NavGrid
    private(set) var soldiers: [Soldier] = []
    private var byId: [Int: Soldier] = [:]
    var grenades: [Grenade] = []
    let zones: [ControlZone]
    var time: CGFloat = 0
    /// The team that has to break through (the other team defends).
    let attackers: Team
    var defenders: Team { attackers.opponent }
    /// Index of the sector currently under attack (0 = A).
    var sector = 0
    /// Attacker respawns left.
    var tickets = BreakthroughConfig.attackerTickets
    /// Set when the battle is over.
    var result: MatchResult?
    private var nextId = 1

    init(layout: MapLayout, attackers: Team) {
        let arena = ArenaMap(layout: layout)
        var grid = NavGrid(size: arena.size, cellSize: GameConfig.navCellSize)
        grid.rebuild(rects: arena.obstacles.map { $0.rect }, padding: GameConfig.navPadding)
        map = arena
        nav = grid
        self.attackers = attackers
        var list: [ControlZone] = []
        for (index, sector) in arena.sectors.enumerated() {
            for spec in sector.zones {
                list.append(ControlZone(name: spec.name, center: spec.center, radius: ZoneConfig.radius,
                                        sector: index, owner: attackers.opponent))
            }
        }
        zones = list
    }

    var currentSector: BreakthroughConfig.SectorSpec {
        map.sectors[Swift.min(sector, map.sectors.count - 1)]
    }

    /// The two zones being fought over right now.
    var activeZones: [ControlZone] { zones.filter { $0.sector == sector } }

    /// Where a team spawns at the moment (moves forward as sectors fall).
    func spawnZone(_ team: Team) -> CGRect {
        team == attackers ? currentSector.attackerSpawn : currentSector.defenderSpawn
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

import CoreGraphics

/// All live state of one battle. Holds data only; systems implement behaviour.
@MainActor
final class BattleWorld {
    let map = ArenaMap()
    private(set) var nav: NavGrid
    private(set) var soldiers: [Soldier] = []
    private var byId: [Int: Soldier] = [:]
    var grenades: [Grenade] = []
    var time: CGFloat = 0
    var winner: Team?
    private var nextId = 1

    init() {
        var grid = NavGrid(size: MapConfig.size, cellSize: GameConfig.navCellSize)
        grid.rebuild(rects: ArenaMap().obstacles.map { $0.rect }, padding: GameConfig.navPadding)
        nav = grid
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

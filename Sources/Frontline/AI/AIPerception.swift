import CoreGraphics

/// What an AI hero currently knows about its surroundings (refreshed every think step).
@MainActor
final class AIPerception {
    let hero: Hero
    unowned let ctx: GameContext
    private(set) var enemyHeroes: [Hero] = []
    private(set) var enemyUnits: [Entity] = []
    private(set) var enemyStructures: [Structure] = []
    private(set) var allyHeroes: [Hero] = []
    private(set) var allyUnits: [Entity] = []
    private(set) var neutrals: [Entity] = []

    init(hero: Hero, ctx: GameContext) {
        self.hero = hero
        self.ctx = ctx
    }

    func refresh() {
        enemyHeroes = []; enemyUnits = []; enemyStructures = []
        allyHeroes = []; allyUnits = []; neutrals = []
        let nearby = ctx.world.grid.query(center: hero.position, radius: AIConfig.awarenessRadius)
        for entity in nearby where entity !== hero && entity.isAlive {
            if entity.team == hero.team {
                if let ally = entity as? Hero { allyHeroes.append(ally) } else if !(entity is Structure) { allyUnits.append(entity) }
                continue
            }
            guard ctx.vision.canSee(hero.team, entity) else { continue }
            if entity.team == .neutral {
                neutrals.append(entity)
            } else if let enemy = entity as? Hero {
                enemyHeroes.append(enemy)
            } else if let structure = entity as? Structure {
                enemyStructures.append(structure)
            } else {
                enemyUnits.append(entity)
            }
        }
    }

    var nearestEnemyHero: Hero? {
        enemyHeroes.min { $0.position.distance(to: hero.position) < $1.position.distance(to: hero.position) }
    }

    func enemiesNear(_ radius: CGFloat) -> Int {
        enemyHeroes.filter { $0.position.distance(to: hero.position) < radius }.count
            + enemyUnits.filter { $0.position.distance(to: hero.position) < radius * 0.7 }.count
    }

    /// Enemy structure whose attack range covers `point`.
    func dangerousStructure(at point: CGPoint) -> Structure? {
        ctx.world.structures.first { s in
            guard s.isAlive, s.team != hero.team, let range = s.attack?.range else { return false }
            return s.position.distance(to: point) <= range + hero.radius + 40
        }
    }

    /// True when allied troops are inside the structure's range and it is shooting at one of them.
    func isTanked(_ structure: Structure) -> Bool {
        guard let range = structure.attack?.range else { return true }
        let tanks = ctx.world.grid.query(center: structure.position, radius: range).filter {
            $0.team == hero.team && !($0 is Hero) && !($0 is Structure) && $0.isAlive
        }
        guard tanks.count >= 2 else { return false }
        if let targetId = structure.targetId, targetId == hero.id { return false }
        return true
    }

    /// Where an AI hero should stand in its lane: a bit behind the frontmost allied troop.
    func laneFront(_ lane: Lane) -> CGPoint {
        let world = ctx.world
        let path = world.map.path(lane, for: hero.team)
        var best: CGFloat = -1
        for entity in world.entities where entity.team == hero.team && entity.kind.isTroop && entity.isAlive {
            guard path.distance(from: entity.position) < 300 else { continue }
            best = Swift.max(best, path.progress(of: entity.position))
        }
        if best < 0 {
            for structure in world.structures where structure.team == hero.team && structure.lane == lane {
                best = Swift.max(best, path.progress(of: structure.position))
            }
        }
        if best < 0 { best = 400 }
        return path.point(atDistance: Swift.max(150, best - AIConfig.laneFrontOffset))
    }
}

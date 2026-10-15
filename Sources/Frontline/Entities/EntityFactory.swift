import CoreGraphics

/// Creates entities from `Data/` configs and registers them in the world.
@MainActor
struct EntityFactory {
    let world: GameWorld

    /// Creates a non-hero, non-structure unit of the right class and adds it to the world.
    @discardableResult
    func makeUnit(_ kind: EntityKind, team: Team, at position: CGPoint) -> Entity {
        let stats = UnitCatalog.stats(for: kind)
        let id = world.makeId()
        let entity: Entity
        switch kind {
        case .tank, .apc, .superTank, .summonTank, .depotGuardian:
            let vehicle = Vehicle(id: id, kind: kind, team: team, position: position, stats: stats)
            if kind == .apc { vehicle.deploysOnDeath = WaveConfig.apcDeployCount }
            entity = vehicle
        case .helicopter:
            entity = Aircraft(id: id, kind: kind, team: team, position: position, stats: stats)
        case .sentry:
            entity = Turret(id: id, kind: kind, team: team, position: position, stats: stats)
        default:
            entity = Infantry(id: id, kind: kind, team: team, position: position, stats: stats)
        }
        world.add(entity)
        return entity
    }

    /// A lane troop that walks `path` toward the enemy base.
    @discardableResult
    func makeTroop(_ kind: EntityKind, team: Team, path: LanePath, multiplier: CGFloat) -> Entity {
        let jitter = CGPoint(x: CGFloat.random(in: -18...18), y: CGFloat.random(in: -18...18))
        let start = path.point(atDistance: 120) + jitter
        let entity = makeUnit(kind, team: team, at: start)
        entity.scaleStats(hp: multiplier, damage: multiplier)
        entity.brain = LaneBrain(path: path, startIndex: path.nextWaypointIndex(from: start))
        return entity
    }

    @discardableResult
    func makeStructure(_ kind: EntityKind, role: StructureRole, team: Team, lane: Lane?,
                       at position: CGPoint) -> Structure {
        let structure = Structure(id: world.makeId(), kind: kind, team: team, position: position,
                                  role: role, lane: lane)
        if structure.attack != nil {
            structure.brain = StructureBrain()
        }
        world.add(structure)
        return structure
    }

    @discardableResult
    func makeHero(name: String, team: Team, isPlayer: Bool) -> Hero {
        let hero = Hero(id: world.makeId(), name: name, team: team, isPlayer: isPlayer,
                        spawn: world.map.spawnPoint(team))
        world.add(hero)
        return hero
    }

    @discardableResult
    func makeNeutral(_ kind: EntityKind, at position: CGPoint, leash: CGFloat) -> Entity {
        let entity = makeUnit(kind, team: .neutral, at: position)
        entity.brain = CampBrain(home: position, leash: leash)
        return entity
    }
}

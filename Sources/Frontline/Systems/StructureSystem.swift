import CoreGraphics

/// Structure rules: destruction order (invulnerability), bunker hero-aggro and barracks bookkeeping.
@MainActor
final class StructureSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
        ctx.bus.subscribe { [unowned self] event in
            switch event {
            case .heroAttackedHero(let attackerId, let victimId):
                self.handleHeroAggro(attackerId: attackerId, victimId: victimId)
            case .killed(let victimId, _):
                if let structure = self.ctx.world.entity(victimId) as? Structure {
                    self.handleDestroyed(structure)
                }
            default:
                break
            }
        }
    }

    func update() {
        let world = ctx.world
        for team in Team.playable {
            let owned = world.structures.filter { $0.team == team && $0.isAlive }
            for lane in Lane.allCases {
                let laneStructures = owned.filter { $0.lane == lane }
                let outerAlive = laneStructures.contains { $0.bunkerTier == 1 }
                let innerAlive = laneStructures.contains { $0.bunkerTier == 2 }
                for structure in laneStructures {
                    if structure.bunkerTier == 2 {
                        structure.isInvulnerable = outerAlive
                    } else if structure.isBarracks {
                        structure.isInvulnerable = outerAlive || innerAlive
                    } else {
                        structure.isInvulnerable = false
                    }
                }
            }
            let barracksAlive = owned.filter { $0.isBarracks }.count
            for hq in owned where hq.isHQ {
                hq.isInvulnerable = barracksAlive >= Lane.allCases.count
            }
        }
    }

    /// Bunkers switch to a hero who attacks an allied hero inside their range.
    private func handleHeroAggro(attackerId: Int, victimId: Int) {
        let world = ctx.world
        guard let attacker = world.entity(attackerId), let victim = world.entity(victimId) else { return }
        for structure in world.structures where structure.isAlive && structure.team == victim.team {
            guard let attack = structure.attack, let brain = structure.brain as? StructureBrain else { continue }
            let attackerInRange = structure.position.distance(to: attacker.position) <= attack.range + attacker.radius
            let victimNearby = structure.position.distance(to: victim.position) <= attack.range + 150
            if attackerInRange && victimNearby {
                brain.forceTarget(attacker.id, duration: StructureConfig.heroAggroDuration)
            }
        }
    }

    private func handleDestroyed(_ structure: Structure) {
        let winnerTeam = structure.team.opponent
        if structure.isBarracks, let lane = structure.lane {
            ctx.world.barracksDestroyed[winnerTeam, default: []].insert(lane)
        }
        ctx.bus.publish(.structureDestroyed(structureId: structure.id, team: structure.team, title: structure.title))
        if !structure.isHQ {
            ctx.bus.publish(.announcement(text: "\(winnerTeam.displayName) destroyed the \(structure.team.displayName) \(structure.title)",
                                          team: winnerTeam))
        }
    }
}

import CoreGraphics

/// Team-level coordination: builds squads, decides push / hold / retreat, sends idle squads to
/// support nearby fights, sends squads to take and defend control zones and merges decimated squads.
@MainActor
final class SquadCoordinator {
    unowned let ctx: BattleContext
    private(set) var squads: [Squad] = []
    private var timer: CGFloat = 0
    private var objectiveTimer: CGFloat = 0

    init(ctx: BattleContext, bots: [SoldierAI]) {
        self.ctx = ctx
        var nextId = 1
        for team in Team.playable {
            // A few bots per team are rogues: lone flankers outside any squad.
            let allBots = bots.filter { $0.soldier.team == team }
            let rogueCount = Swift.min(AIConfig.roguesPerTeam, allBots.count / 4)
            for bot in allBots.suffix(rogueCount) { bot.isRogue = true }
            let teamBots = Array(allBots.dropLast(rogueCount))
            let count = Int((CGFloat(teamBots.count) / CGFloat(AIConfig.squadSize)).rounded(.up))
            for squadIndex in 0..<count {
                let squad = Squad(id: nextId, team: team, role: squadIndex)
                nextId += 1
                let start = squadIndex * AIConfig.squadSize
                let end = Swift.min(start + AIConfig.squadSize, teamBots.count)
                for bot in teamBots[start..<end] { squad.add(bot) }
                squads.append(squad)
            }
        }
    }

    func update(dt: CGFloat) {
        timer -= dt
        guard timer <= 0 else { return }
        timer = AIConfig.squadUpdateInterval
        mergeWeakSquads()
        objectiveTimer -= AIConfig.squadUpdateInterval
        if objectiveTimer <= 0 {
            objectiveTimer = AIConfig.objectiveInterval
            // Re-number roles from the surviving squads so merges never leave a team without a defender.
            for team in Team.playable {
                for (index, squad) in squads.filter({ $0.team == team }).enumerated() { squad.role = index }
            }
            for squad in squads { assignObjective(squad) }
        }
        for squad in squads where !squad.members.isEmpty {
            decideStance(squad)
            if let flank = squad.flankPoint, let leader = squad.leader,
               leader.soldier.position.distance(to: flank) < AIConfig.flankReachedDistance {
                squad.flankPoint = nil
            }
        }
        assignSupport()
    }

    private func decideStance(_ squad: Squad) {
        let now = ctx.world.time
        guard squad.hasFreshContact(at: now), let contact = squad.contactPoint, let center = squad.centroid else {
            squad.stance = squad.supportPoint == nil ? .advance : .support
            return
        }
        squad.supportPoint = nil
        let allies = ctx.world.soldiers.filter {
            $0.team == squad.team && $0.isAlive && $0.position.distance(to: center) < 500
        }.count
        let enemies = Swift.max(1, squad.knownEnemyIds.count, enemiesNear(contact, team: squad.team))
        let ratio = CGFloat(allies) / CGFloat(enemies)
        if ratio < AIConfig.retreatRatio || squad.averageHealth < AIConfig.retreatHealth {
            squad.stance = .retreat
        } else if ratio >= AIConfig.pushRatio {
            squad.stance = .push
        } else {
            squad.stance = .hold
        }
    }

    /// Enemies near a contact point that the squad's team can currently see.
    private func enemiesNear(_ point: CGPoint, team: Team) -> Int {
        let world = ctx.world
        let watchers = world.soldiers.filter { $0.team == team && $0.isAlive && $0.position.distance(to: point) < 900 }
        return world.soldiers.filter { enemy in
            enemy.team != team && enemy.isAlive && enemy.position.distance(to: point) < 400
                && watchers.contains { world.map.hasLineOfSight($0.position, enemy.position) }
        }.count
    }

    /// Zones: home (near own spawn), middle, enemy (near enemy spawn).
    private func zones(for team: Team) -> (home: ControlZone, middle: ControlZone, enemy: ControlZone) {
        let all = ctx.world.zones
        return team == .blue ? (all[0], all[1], all[2]) : (all[2], all[1], all[0])
    }

    /// Defenders guard the home zone (retaking it if lost); attackers go for the middle first,
    /// then for whatever zone the team does not own yet, nearest first.
    private func assignObjective(_ squad: Squad) {
        let set = zones(for: squad.team)
        if squad.role == 1 {
            setObjective(squad, set.home, flank: false)
            return
        }
        let homeLost = set.home.owner != squad.team && set.home.owner != nil
        if homeLost && squad.role == 2 {
            setObjective(squad, set.home, flank: false)
            return
        }
        if let current = squad.objective, current.owner != squad.team { return }
        let origin = squad.centroid ?? set.home.center
        let candidates = [set.middle, set.enemy, set.home].filter { $0.owner != squad.team }
        // Roles 2 and 3 take the long way round the top / bottom of the map instead of going through the middle.
        let flank = squad.role == 2 || squad.role == 3
        if let target = candidates.min(by: { score($0, origin, squad.team) < score($1, origin, squad.team) }) {
            setObjective(squad, target, flank: flank)
        } else {
            // Everything is ours: push toward the enemy zone and hold it.
            setObjective(squad, squad.role % 2 == 0 ? set.enemy : set.middle, flank: flank)
        }
    }

    private func setObjective(_ squad: Squad, _ zone: ControlZone, flank: Bool) {
        guard squad.objective !== zone else { return }
        squad.objective = zone
        squad.flankPoint = nil
        guard flank, let origin = squad.centroid, abs(zone.center.x - origin.x) > AIConfig.flankMinDistance else { return }
        let size = ctx.world.map.size
        let edgeY = squad.role == 2 ? size.height - AIConfig.flankEdgeMargin : AIConfig.flankEdgeMargin
        squad.flankPoint = ctx.world.nav.nearestWalkable(CGPoint(x: (origin.x + zone.center.x) / 2, y: edgeY))
    }

    /// Lower is better: distance, with the middle zone preferred.
    private func score(_ zone: ControlZone, _ origin: CGPoint, _ team: Team) -> CGFloat {
        let bonus: CGFloat = zone === zones(for: team).middle ? -400 : 0
        return zone.center.distance(to: origin) + bonus
    }

    /// Idle squads move toward the nearest fight of their team.
    private func assignSupport() {
        let now = ctx.world.time
        for squad in squads where squad.stance == .advance || squad.stance == .support {
            guard let center = squad.centroid else { continue }
            var best: CGPoint?
            var bestDistance = AIConfig.supportRadius
            for other in squads where other !== squad && other.team == squad.team && other.hasFreshContact(at: now) {
                guard let contact = other.contactPoint else { continue }
                let distance = contact.distance(to: center)
                if distance < bestDistance {
                    bestDistance = distance
                    best = contact
                }
            }
            squad.supportPoint = best
            squad.stance = best == nil ? .advance : .support
        }
    }

    /// Squads with only a couple of soldiers left join the nearest living squad.
    private func mergeWeakSquads() {
        for squad in squads where !squad.members.isEmpty {
            let living = squad.alive.count
            let pending = squad.members.filter { $0.soldier.isAwaitingRespawn }.count
            guard living + pending <= AIConfig.mergeThreshold, living > 0 || pending > 0 else { continue }
            let origin = squad.centroid ?? squad.members[0].soldier.position
            let target = squads
                .filter { $0 !== squad && $0.team == squad.team && $0.alive.count > AIConfig.mergeThreshold }
                .min { ($0.centroid ?? origin).distance(to: origin) < ($1.centroid ?? origin).distance(to: origin) }
            if let target = target { squad.merge(into: target) }
        }
        squads.removeAll { $0.members.isEmpty }
    }
}

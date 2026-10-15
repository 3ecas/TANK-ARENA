import CoreGraphics

/// Team-level coordination: builds squads, decides push / hold / retreat, sends idle squads to
/// support nearby fights, advances squads along their routes and merges decimated squads.
@MainActor
final class SquadCoordinator {
    unowned let ctx: BattleContext
    private(set) var squads: [Squad] = []
    private var timer: CGFloat = 0

    init(ctx: BattleContext, bots: [SoldierAI]) {
        self.ctx = ctx
        var nextId = 1
        for team in Team.playable {
            let teamBots = bots.filter { $0.soldier.team == team }
            let count = Int((CGFloat(teamBots.count) / CGFloat(AIConfig.squadSize)).rounded(.up))
            for squadIndex in 0..<count {
                let route = ctx.world.map.route(BattleSetup.routeIndex(for: squadIndex, of: count), for: team)
                let squad = Squad(id: nextId, team: team, route: route)
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
        for squad in squads where !squad.members.isEmpty {
            decideStance(squad)
            if squad.stance == .advance { progressRoute(squad) }
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

    private func progressRoute(_ squad: Squad) {
        guard let leader = squad.leader, !squad.route.isEmpty, squad.isGathered else { return }
        let waypoint = squad.route[squad.routeIndex]
        guard leader.soldier.position.distance(to: waypoint) < 90 else { return }
        if squad.routeIndex < squad.route.count - 1 {
            squad.routeIndex += 1
        } else {
            // Reached the far side: sweep back along another route.
            let next = Int.random(in: 0..<ctx.world.map.routeCount)
            squad.route = ctx.world.map.route(next, for: squad.team).reversed()
            squad.routeIndex = 0
        }
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

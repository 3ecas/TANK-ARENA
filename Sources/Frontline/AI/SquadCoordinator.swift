import CoreGraphics

/// Team-level coordination: builds squads, decides push / hold / retreat, sends idle squads to
/// support nearby fights, sends attackers to their target bomb site and defenders to guard both sites
/// (everyone converges on the bomb once it is planted), and merges decimated squads.
@MainActor
final class SquadCoordinator {
    unowned let ctx: BattleContext
    private(set) var squads: [Squad] = []
    private var timer: CGFloat = 0
    private var objectiveTimer: CGFloat = 0
    private var bombWasPlanted = false
    /// The site the attackers go for this round.
    private let attackTarget: BombSite?

    init(ctx: BattleContext, bots: [SoldierAI]) {
        self.ctx = ctx
        attackTarget = ctx.world.sites.randomElement()
        var nextId = 1
        let carrierId = ctx.world.bomb.carrierId
        for team in Team.playable {
            // A few bots per team are rogues: lone flankers outside any squad (never the bomb carrier).
            let allBots = bots.filter { $0.soldier.team == team }
            let rogueCount = Swift.min(AIConfig.roguesPerTeam, allBots.count / 4)
            let rogues = Array(allBots.filter { $0.soldier.id != carrierId }.suffix(rogueCount))
            for bot in rogues { bot.isRogue = true }
            let teamBots = allBots.filter { !$0.isRogue }
            let size = team == ctx.world.attackers ? AIConfig.squadSize : AIConfig.defenderSquadSize
            let count = Int((CGFloat(teamBots.count) / CGFloat(size)).rounded(.up))
            for squadIndex in 0..<count {
                let squad = Squad(id: nextId, team: team, role: squadIndex)
                nextId += 1
                let start = squadIndex * size
                let end = Swift.min(start + size, teamBots.count)
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
        // The bomb was just planted: everyone gets a new objective right away.
        if ctx.world.bomb.isPlanted != bombWasPlanted {
            bombWasPlanted = ctx.world.bomb.isPlanted
            objectiveTimer = 0
        }
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
               leader.soldier.position.distance(to: flank) < AIConfig.flankReachedDistance
                || ctx.world.time > squad.flankDeadline {
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

    /// Before the plant: attackers all go for one site; defender pairs split over both sites.
    /// After the plant: both teams converge on the planted site (attackers to guard it, defenders to defuse).
    private func assignObjective(_ squad: Squad) {
        let world = ctx.world
        guard !world.sites.isEmpty else { return }
        if world.bomb.isPlanted, let planted = world.bomb.site {
            setObjective(squad, planted, flank: false)
            return
        }
        if squad.team == world.attackers {
            if let target = attackTarget { setObjective(squad, target, flank: squad.role == 1) }
        } else {
            setObjective(squad, world.sites[squad.role % world.sites.count], flank: false)
        }
    }

    private func setObjective(_ squad: Squad, _ zone: BombSite, flank: Bool) {
        guard squad.objective !== zone else { return }
        squad.objective = zone
        squad.flankPoint = nil
        guard flank, let origin = squad.centroid, abs(zone.center.x - origin.x) > AIConfig.flankMinDistance else { return }
        let size = ctx.world.map.size
        let edgeY = squad.role == 2 ? size.height - AIConfig.flankEdgeMargin : AIConfig.flankEdgeMargin
        let nav = ctx.world.nav
        let point = nav.nearestWalkable(CGPoint(x: (origin.x + zone.center.x) / 2, y: edgeY))
        guard nav.findPath(from: origin, to: point) != nil else { return }
        squad.flankPoint = point
        squad.flankDeadline = ctx.world.time + AIConfig.flankTimeout
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

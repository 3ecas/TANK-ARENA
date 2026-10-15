import CoreGraphics

enum SquadStance {
    /// Moving in formation to the squad's control zone (then holding it).
    case advance
    /// Winning the fight: close in on the enemy.
    case push
    /// Even fight: hold cover at fighting distance.
    case hold
    /// Losing the fight: fall back a bit and cover.
    case retreat
    /// Going to help another squad's fight.
    case support
}

/// A group of ~5 bots that moves together, shares contacts and decides as one whether to push or fall back.
@MainActor
final class Squad {
    let id: Int
    let team: Team
    private(set) var members: [SoldierAI] = []
    /// Control zone the squad is taking or defending.
    var objective: ControlZone?
    /// Waypoint on the edge of the map the squad passes through first to flank the objective.
    var flankPoint: CGPoint?
    /// Squad role inside its team: 1 = defends the home zone, others attack.
    var role: Int
    var stance: SquadStance = .advance
    var contactPoint: CGPoint?
    var contactTime: CGFloat = -100
    var supportPoint: CGPoint?

    init(id: Int, team: Team, role: Int) {
        self.id = id
        self.team = team
        self.role = role
    }

    func add(_ member: SoldierAI) {
        members.append(member)
        member.squad = self
    }

    /// Moves every member into `other` (joining forces).
    func merge(into other: Squad) {
        for member in members { other.add(member) }
        members.removeAll()
    }

    var alive: [SoldierAI] { members.filter { $0.soldier.isAlive } }
    var leader: SoldierAI? { alive.first }

    var centroid: CGPoint? {
        let living = alive
        guard !living.isEmpty else { return nil }
        return living.reduce(CGPoint.zero) { $0 + $1.soldier.position } / CGFloat(living.count)
    }

    var averageHealth: CGFloat {
        let living = alive
        guard !living.isEmpty else { return 0 }
        return living.reduce(CGFloat(0)) { $0 + $1.soldier.hpFraction } / CGFloat(living.count)
    }

    func reportContact(_ position: CGPoint, time: CGFloat) {
        contactPoint = position
        contactTime = time
    }

    func hasFreshContact(at time: CGFloat) -> Bool {
        contactPoint != nil && time - contactTime < AIConfig.contactMemory
    }

    /// True when every living member (except far-away respawners) is close to the leader.
    var isGathered: Bool {
        guard let leader = leader else { return true }
        return alive.allSatisfy { member in
            let d = member.soldier.position.distance(to: leader.soldier.position)
            return d <= AIConfig.gatherRadius || d >= AIConfig.stragglerRadius
        }
    }

    /// Distinct enemies the squad is currently fighting.
    var knownEnemyIds: Set<Int> {
        Set(alive.compactMap { $0.targetId })
    }

    /// Cover spots already taken by squad mates.
    func coverSpots(excluding member: SoldierAI) -> [CGPoint] {
        alive.filter { $0 !== member }.compactMap { $0.cover?.position }
    }

    /// A spot inside the objective zone, spread out per member so the squad covers the area.
    func zoneSpot(for member: SoldierAI) -> CGPoint? {
        guard let zone = objective, let index = alive.firstIndex(where: { $0 === member }) else { return nil }
        let count = Swift.max(1, alive.count)
        let angle = CGFloat(index) / CGFloat(count) * 2 * .pi + CGFloat(id)
        return zone.center + CGPoint(angle: angle) * (zone.radius * 0.55)
    }

    /// Formation slot behind the leader: two columns, staggered rows.
    func formationPosition(for member: SoldierAI) -> CGPoint? {
        guard let leader = leader, leader !== member,
              let index = alive.firstIndex(where: { $0 === member }) else { return nil }
        let heading: CGPoint
        if let goal = leader.travelGoal, goal.distance(to: leader.soldier.position) > 10 {
            heading = (goal - leader.soldier.position).normalized
        } else {
            heading = CGPoint(angle: leader.soldier.facing)
        }
        let slot = index - 1
        let row = CGFloat(slot / 2)
        let side: CGFloat = slot % 2 == 0 ? 1 : -1
        return leader.soldier.position - heading * (45 + 35 * row) + heading.perpendicular * (38 * side)
    }
}

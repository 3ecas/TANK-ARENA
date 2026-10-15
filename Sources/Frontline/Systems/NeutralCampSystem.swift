import CoreGraphics

/// Mercenary camps and the Heavy Armor Depot guardian (spawning, respawning, rewards).
@MainActor
final class NeutralCampSystem {
    private struct Camp {
        let position: CGPoint
        let members: [EntityKind]
        let isDepot: Bool
        var memberIds: [Int] = []
        var respawnTimer: CGFloat
    }

    unowned let ctx: GameContext
    private var camps: [Camp] = []

    init(ctx: GameContext) {
        self.ctx = ctx
        for position in ObjectiveConfig.campPositions {
            camps.append(Camp(position: position, members: ObjectiveConfig.campMembers, isDepot: false,
                              respawnTimer: ObjectiveConfig.campFirstSpawn))
        }
        camps.append(Camp(position: ObjectiveConfig.depotPosition, members: [.depotGuardian], isDepot: true,
                          respawnTimer: ObjectiveConfig.depotFirstSpawn))
        ctx.bus.subscribe { [unowned self] event in
            if case .killed(let victimId, let killerId) = event,
               let victim = self.ctx.world.entity(victimId), victim.kind == .depotGuardian {
                self.rewardDepot(victim: victim, killerId: killerId)
            }
        }
    }

    func update(dt: CGFloat) {
        let world = ctx.world
        for i in camps.indices {
            if !camps[i].memberIds.isEmpty {
                let anyAlive = camps[i].memberIds.contains { world.entity($0)?.isAlive == true }
                if !anyAlive {
                    camps[i].memberIds = []
                    camps[i].respawnTimer = camps[i].isDepot ? ObjectiveConfig.depotRespawn : ObjectiveConfig.campRespawn
                }
                continue
            }
            camps[i].respawnTimer -= dt
            if camps[i].respawnTimer <= 0 { spawn(&camps[i]) }
        }
    }

    private func spawn(_ camp: inout Camp) {
        let leash = camp.isDepot ? ObjectiveConfig.depotLeash : ObjectiveConfig.campLeash
        for (index, kind) in camp.members.enumerated() {
            let offset = camp.members.count > 1
                ? CGPoint(angle: CGFloat(index) * 2 * .pi / CGFloat(camp.members.count), length: 45)
                : .zero
            let unit = ctx.factory.makeNeutral(kind, at: camp.position + offset, leash: leash)
            camp.memberIds.append(unit.id)
        }
        if camp.isDepot {
            ctx.bus.publish(.announcement(text: "The Heavy Armor Depot guardian has deployed!", team: nil))
        }
    }

    private func rewardDepot(victim: Entity, killerId: Int?) {
        guard let team = KillCredit.rewardedTeam(victim: victim, killerId: killerId, world: ctx.world) else { return }
        ctx.economy.grantTeamGold(team, ObjectiveConfig.depotTeamGold)
        ctx.commandPoints.grantTeam(team, ObjectiveConfig.depotCommandPoints)
        let path = ctx.world.map.path(.mid, for: team)
        let tank = ctx.factory.makeUnit(.superTank, team: team, at: path.point(atDistance: 160))
        tank.brain = LaneBrain(path: path, startIndex: path.nextWaypointIndex(from: tank.position))
        ctx.bus.publish(.objectiveCaptured(title: "Heavy Armor Depot", team: team))
        ctx.bus.publish(.announcement(text: "\(team.displayName) team secured the Armor Depot: a Super Tank rolls out!",
                                      team: team))
    }
}

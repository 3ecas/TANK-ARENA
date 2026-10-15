import CoreGraphics

/// Scoreboard bookkeeping (K/D/A, troop kills) and kill announcements.
@MainActor
final class ScoreSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
        ctx.bus.subscribe { [unowned self] event in
            if case .killed(let victimId, let killerId) = event { self.handleKill(victimId, killerId) }
        }
    }

    private func handleKill(_ victimId: Int, _ killerId: Int?) {
        let world = ctx.world
        guard let victim = world.entity(victimId) else { return }
        let killer = world.hero(killerId)
        if let hero = victim as? Hero {
            hero.deaths += 1
            let assistants = KillCredit.assistants(of: hero, killerId: killerId, world: world)
            for assistant in assistants { assistant.assists += 1 }
            if let killer = killer, killer.team != hero.team {
                killer.kills += 1
                ctx.bus.publish(.announcement(text: "\(killer.name) eliminated \(hero.name)", team: killer.team))
            } else {
                ctx.bus.publish(.announcement(text: "\(hero.name) was killed", team: hero.team.opponent))
            }
        } else if let killer = killer, !(victim is Structure), killer.team != victim.team {
            killer.troopKills += 1
        }
    }

    func teamKills(_ team: Team) -> Int {
        ctx.world.heroes(of: team).reduce(0) { $0 + $1.kills }
    }
}

import CoreGraphics

/// Command Points: earned from kills, assists, objectives and slowly over time;
/// spent on ultimate-tier abilities.
@MainActor
final class CommandPointSystem {
    unowned let ctx: GameContext
    private var passiveTimer: CGFloat = EconomyConfig.cpPassiveInterval

    init(ctx: GameContext) {
        self.ctx = ctx
        ctx.bus.subscribe { [unowned self] event in
            switch event {
            case .killed(let victimId, let killerId):
                self.handleKill(victimId, killerId)
            case .objectiveCaptured(_, let team):
                self.grantTeam(team, EconomyConfig.cpPerObjective)
            default:
                break
            }
        }
    }

    func update(dt: CGFloat) {
        passiveTimer -= dt
        if passiveTimer <= 0 {
            passiveTimer += EconomyConfig.cpPassiveInterval
            for hero in ctx.world.heroes { grant(hero, 1) }
        }
    }

    func grant(_ hero: Hero, _ amount: Int) {
        hero.commandPoints = Swift.min(EconomyConfig.maxCommandPoints, hero.commandPoints + amount)
    }

    func grantTeam(_ team: Team, _ amount: Int) {
        for hero in ctx.world.heroes(of: team) { grant(hero, amount) }
    }

    func canAfford(_ hero: Hero, _ cost: Int) -> Bool { hero.commandPoints >= cost }

    func spend(_ hero: Hero, _ cost: Int) {
        hero.commandPoints = Swift.max(0, hero.commandPoints - cost)
    }

    private func handleKill(_ victimId: Int, _ killerId: Int?) {
        let world = ctx.world
        guard let victim = world.entity(victimId) else { return }
        if let hero = victim as? Hero {
            if let killer = world.hero(killerId), killer.team != hero.team {
                grant(killer, EconomyConfig.cpPerKill)
            }
            for assistant in KillCredit.assistants(of: hero, killerId: killerId, world: world) {
                grant(assistant, EconomyConfig.cpPerAssist)
            }
        } else if let structure = victim as? Structure, structure.team != .neutral {
            grantTeam(structure.team.opponent, EconomyConfig.cpPerStructure)
        }
    }
}

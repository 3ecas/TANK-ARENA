import CoreGraphics

/// Gold: passive income, last-hit bounties, hero kills/assists and structure rewards.
/// Also routes kill XP to the experience system.
@MainActor
final class EconomySystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
        ctx.bus.subscribe { [unowned self] event in
            if case .killed(let victimId, let killerId) = event { self.handleKill(victimId, killerId) }
        }
    }

    func update(dt: CGFloat) {
        for hero in ctx.world.heroes {
            hero.goldRemainder += EconomyConfig.passiveGoldPerSecond * dt * multiplier(for: hero)
            let whole = Int(hero.goldRemainder)
            if whole > 0 {
                hero.gold += whole
                hero.goldRemainder -= CGFloat(whole)
            }
        }
    }

    func grantGold(_ hero: Hero, _ amount: Int, at position: CGPoint? = nil) {
        let value = Int((CGFloat(amount) * multiplier(for: hero)).rounded())
        guard value > 0 else { return }
        hero.gold += value
        if let position = position {
            ctx.bus.publish(.goldGained(heroId: hero.id, amount: value, position: position))
        }
    }

    func grantTeamGold(_ team: Team, _ amount: Int) {
        for hero in ctx.world.heroes(of: team) { grantGold(hero, amount) }
    }

    private func multiplier(for hero: Hero) -> CGFloat {
        hero.team == .red ? ctx.tuning.enemyGoldMultiplier : 1
    }

    private func handleKill(_ victimId: Int, _ killerId: Int?) {
        let world = ctx.world
        guard let victim = world.entity(victimId),
              let team = KillCredit.rewardedTeam(victim: victim, killerId: killerId, world: world) else { return }
        let killerHero = world.hero(killerId)

        if let hero = victim as? Hero {
            if let killer = killerHero, killer.team != hero.team {
                grantGold(killer, EconomyConfig.heroKillGold + EconomyConfig.heroKillGoldPerLevel * hero.level,
                          at: hero.position)
            }
            for assistant in KillCredit.assistants(of: hero, killerId: killerId, world: world) {
                grantGold(assistant, EconomyConfig.assistGold, at: assistant.position)
            }
            let xp = EconomyConfig.heroKillXpBase + EconomyConfig.heroKillXpPerLevel * CGFloat(hero.level)
            shareXP(xp, team: team, around: hero.position)
        } else if let structure = victim as? Structure {
            let gold = structure.isBarracks ? StructureConfig.teamGoldBarracks : StructureConfig.teamGoldBunker
            if !structure.isHQ { grantTeamGold(team, gold) }
            shareXP(structure.xpBounty, team: team, around: structure.position)
        } else {
            if let killer = killerHero, killer.team != victim.team {
                grantGold(killer, victim.goldBounty, at: victim.position)
            }
            shareXP(victim.xpBounty, team: team, around: victim.position)
        }
    }

    private func shareXP(_ amount: CGFloat, team: Team, around position: CGPoint) {
        let heroes = KillCredit.nearbyHeroes(of: team, around: position, world: ctx.world)
        guard !heroes.isEmpty else { return }
        let share = amount * (heroes.count > 1 ? 1.3 : 1) / CGFloat(heroes.count)
        for hero in heroes { ctx.experience.grantXP(hero, share) }
    }
}

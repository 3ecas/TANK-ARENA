import CoreGraphics

/// Creates the initial battlefield: structures on every lane, the player and the AI heroes.
@MainActor
enum MatchSetup {
    static func buildStructures(ctx: GameContext) {
        let world = ctx.world
        let factory = ctx.factory
        for team in Team.playable {
            for lane in Lane.allCases {
                let path = world.map.path(lane, for: team)
                factory.makeStructure(.bunker, role: .bunker(tier: 1), team: team, lane: lane,
                                      at: path.point(atDistance: StructureConfig.outerBunkerDistance))
                factory.makeStructure(.bunker, role: .bunker(tier: 2), team: team, lane: lane,
                                      at: path.point(atDistance: StructureConfig.innerBunkerDistance))
                factory.makeStructure(.barracks, role: .barracks, team: team, lane: lane,
                                      at: path.point(atDistance: StructureConfig.barracksDistance))
            }
            factory.makeStructure(.hq, role: .hq, team: team, lane: nil, at: world.map.hqPosition(team))
        }
    }

    static func makePlayer(ctx: GameContext, loadout: StartingLoadout) -> Hero {
        let player = ctx.factory.makeHero(name: RosterConfig.playerName, team: .blue, isPlayer: true)
        LoadoutManager.grantStarting(loadout.abilities, to: player)
        StatCalculator.apply(to: player)
        player.ammo = player.stats.magSize
        return player
    }

    static func makeAIHeroes(ctx: GameContext) -> [HeroAIController] {
        var controllers: [HeroAIController] = []
        let rosters: [(Team, [RosterEntry])] = [(.blue, RosterConfig.blueAllies), (.red, RosterConfig.redEnemies)]
        for (team, entries) in rosters {
            for (index, entry) in entries.enumerated() {
                let hero = ctx.factory.makeHero(name: entry.name, team: team, isPlayer: false)
                hero.position += CGPoint(angle: CGFloat(index) * 1.3, length: 40)
                let controller = HeroAIController(hero: hero, entry: entry, ctx: ctx)
                hero.ammo = hero.stats.magSize
                controllers.append(controller)
            }
        }
        return controllers
    }
}

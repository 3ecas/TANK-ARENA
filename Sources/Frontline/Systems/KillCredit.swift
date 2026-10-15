import CoreGraphics

/// Helpers to work out who gets credit for a kill.
@MainActor
enum KillCredit {
    /// Heroes (other than the killer) that damaged the victim recently.
    static func assistants(of victim: Entity, killerId: Int?, world: GameWorld) -> [Hero] {
        var result: [Hero] = []
        for (heroId, time) in victim.recentHeroAttackers {
            guard heroId != killerId, world.time - time <= EconomyConfig.assistWindow,
                  let hero = world.hero(heroId), hero.team != victim.team else { continue }
            result.append(hero)
        }
        return result
    }

    /// Living heroes of `team` within the XP share radius of `position`.
    static func nearbyHeroes(of team: Team, around position: CGPoint, world: GameWorld) -> [Hero] {
        world.heroes.filter {
            $0.team == team && $0.isAlive && $0.position.distance(to: position) <= EconomyConfig.xpShareRadius
        }
    }

    /// The team that should be rewarded for a kill.
    static func rewardedTeam(victim: Entity, killerId: Int?, world: GameWorld) -> Team? {
        if let killer = world.entity(killerId), killer.team != victim.team, killer.team != .neutral {
            return killer.team
        }
        if victim.team == .neutral { return nil }
        return victim.team.opponent
    }
}

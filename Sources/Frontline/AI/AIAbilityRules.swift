import CoreGraphics

/// Per-ability usage rules for the AI. Returns where to cast, or nil to hold the ability.
@MainActor
enum AIAbilityRules {
    static func target(for id: AbilityID, hero: Hero, state: HeroAIStateKind, goal: CGPoint?,
                       ctx: GameContext) -> CGPoint? {
        let def = AbilityCatalog.def(id)
        let fighting = state == .trading || state == .ganking || state == .objective
        let enemyHero = nearestEnemyHero(hero, ctx: ctx, within: hero.stats.range + 150)
        let home = (hero.spawnPoint - hero.position).normalized

        switch id {
        case .fragGrenade:
            return bestCluster(hero, ctx: ctx, range: def.range, radius: def.radius, minScore: 3)
        case .artilleryBarrage, .empStrike:
            return bestCluster(hero, ctx: ctx, range: def.range, radius: def.radius, minScore: 4)
        case .strafingRun:
            return bestCluster(hero, ctx: ctx, range: def.range, radius: 140, minScore: 4)
        case .carpetBombing:
            return bestCluster(hero, ctx: ctx, range: def.range, radius: def.radius, minScore: 7)
        case .stim:
            return fighting && enemyHero != nil ? hero.position : nil
        case .deployShield:
            guard (fighting || state == .retreating), hero.hpFraction < 0.75, let enemy = enemyHero else { return nil }
            return enemy.position
        case .smokeGrenade:
            return state == .retreating && enemyHero != nil ? hero.position : nil
        case .medkit:
            return hero.hpFraction < 0.6 ? hero.position : nil
        case .supplyDrop:
            let inBase = ctx.world.map.isInBase(hero.position, team: hero.team)
            return hero.hpFraction < 0.5 && !inBase ? hero.position : nil
        case .uavRecon:
            if state == .ganking || state == .objective, let goal = goal { return goal }
            return nil
        case .sentryTurret:
            return enemyUnitCount(hero, ctx: ctx, radius: 500) >= 3 ? hero.position + home * -80 : nil
        case .reinforcements:
            return fighting || enemyUnitCount(hero, ctx: ctx, radius: 600) >= 3 ? hero.position : nil
        case .callTank:
            let pushing = !ctx.targeting.enemies(of: hero.team, near: hero.position, radius: 900)
                .filter { $0 is Structure }.isEmpty
            return pushing || enemyUnitCount(hero, ctx: ctx, radius: 700) >= 5 ? hero.position + home * -120 : nil
        case .attackHelicopter:
            return (fighting && enemyHero != nil) || enemyUnitCount(hero, ctx: ctx, radius: 700) >= 6
                ? hero.position : nil
        }
    }

    private static func nearestEnemyHero(_ hero: Hero, ctx: GameContext, within radius: CGFloat) -> Hero? {
        ctx.world.heroes
            .filter { $0.team != hero.team && $0.isAlive && ctx.vision.canSee(hero.team, $0)
                && $0.position.distance(to: hero.position) <= radius }
            .min { $0.position.distance(to: hero.position) < $1.position.distance(to: hero.position) }
    }

    private static func enemyUnitCount(_ hero: Hero, ctx: GameContext, radius: CGFloat) -> Int {
        ctx.targeting.enemies(of: hero.team, near: hero.position, radius: radius)
            .filter { !($0 is Structure) }.count
    }

    /// Centre of the best group of enemies within `range`; heroes and vehicles weigh more.
    private static func bestCluster(_ hero: Hero, ctx: GameContext, range: CGFloat, radius: CGFloat,
                                    minScore: CGFloat) -> CGPoint? {
        let enemies = ctx.targeting.enemies(of: hero.team, near: hero.position, radius: range + radius)
            .filter { !($0 is Structure) && $0.isAlive }
        guard !enemies.isEmpty else { return nil }
        var bestScore: CGFloat = 0
        var bestCenter: CGPoint?
        for candidate in enemies where candidate.position.distance(to: hero.position) <= range {
            var score: CGFloat = 0
            var sum = CGPoint.zero
            var count: CGFloat = 0
            for other in enemies where other.position.distance(to: candidate.position) <= radius {
                score += weight(of: other)
                sum += other.position
                count += 1
            }
            if score > bestScore {
                bestScore = score
                bestCenter = sum / Swift.max(count, 1)
            }
        }
        return bestScore >= minScore ? bestCenter : nil
    }

    private static func weight(of entity: Entity) -> CGFloat {
        if entity is Hero { return 3 }
        if entity.isArmored { return 2 }
        return 1
    }
}

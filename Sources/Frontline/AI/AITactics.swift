import CoreGraphics

/// Tactical evaluations shared by AI states (when to trade, whom to gank, which objective to take).
@MainActor
enum AITactics {
    /// An enemy hero worth fighting right now, if any.
    static func tradeOpportunity(_ ai: HeroAIController) -> Hero? {
        let hero = ai.hero
        let p = ai.perception
        guard let enemy = p.nearestEnemyHero, ai.canAttack(enemy),
              enemy.position.distance(to: hero.position) <= hero.stats.range + 200 else { return nil }
        let advantage = hero.hpFraction - enemy.hpFraction
        let favourable = advantage >= ai.tuning.tradeAdvantage || enemy.hpFraction < 0.35
        let outnumbered = p.enemyHeroes.count > p.allyHeroes.count + 1
        if let tower = p.dangerousStructure(at: enemy.position), !p.isTanked(tower) { return nil }
        return favourable && !outnumbered ? enemy : nil
    }

    /// A visible, weakened enemy hero in another lane within roaming distance.
    static func gankTarget(_ ai: HeroAIController) -> Hero? {
        let hero = ai.hero
        let world = ai.world
        let candidates = world.heroes.filter { enemy in
            enemy.team == hero.team.opponent && enemy.isAlive && enemy.hpFraction < 0.65
                && ai.ctx.vision.canSee(hero.team, enemy)
                && enemy.position.distance(to: hero.position) < 2600
                && !world.map.isInBase(enemy.position, team: enemy.team)
                && ai.perception.dangerousStructure(at: enemy.position) == nil
        }
        return candidates.min { $0.hpFraction < $1.hpFraction }
    }

    /// Capture points, camps or the depot guardian, when the situation allows.
    static func objectiveGoal(_ ai: HeroAIController) -> AIObjectiveGoal? {
        let hero = ai.hero
        let world = ai.world
        let roamer = ai.entry.role == .roamer
        let quietLane = ai.perception.enemiesNear(900) == 0
        guard roamer || quietLane, hero.hpFraction > 0.55 else { return nil }
        let reach: CGFloat = roamer ? 2400 : 1300

        for point in world.capturePoints where point.owner != hero.team {
            if point.position.distance(to: hero.position) < reach && CGFloat.random(in: 0...1) < 0.5 {
                return .capture(point.kind, point.position)
            }
        }
        // Mercenary camps the team can see.
        let monsters = world.entities.filter {
            $0.team == .neutral && $0.isAlive && ai.ctx.vision.canSee(hero.team, $0)
        }
        for monster in monsters where monster.position.distance(to: hero.position) < reach {
            if monster.kind == .depotGuardian {
                let allies = world.heroes(of: hero.team).filter {
                    $0.isAlive && $0.position.distance(to: monster.position) < 1400
                }
                if allies.count >= 3 || hero.level >= 13 { return .camp(monster.position) }
                continue
            }
            return .camp(monster.homePosition)
        }
        return nil
    }
}

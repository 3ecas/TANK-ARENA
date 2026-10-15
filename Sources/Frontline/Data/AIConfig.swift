import CoreGraphics

/// Per-difficulty tuning for hero AI.
struct DifficultyTuning {
    /// Seconds between AI "think" steps.
    var reactionTime: CGFloat
    /// Random offset (points) applied to ability aim.
    var aimError: CGFloat
    /// Chance per think step to consider using an ability.
    var abilityChance: CGFloat
    /// Minimum seconds between two ability casts.
    var minCastGap: CGFloat
    /// HP fraction below which the AI retreats.
    var retreatHp: CGFloat
    /// Chance to notice and dodge a telegraphed strike.
    var dodgeChance: CGFloat
    /// Seconds between gank attempts (laners).
    var gankInterval: CGFloat
    /// Gold income multiplier applied to enemy (red) AI heroes.
    var enemyGoldMultiplier: CGFloat
    /// Hp advantage needed before trading with an enemy hero.
    var tradeAdvantage: CGFloat
}

enum AIConfig {
    static func tuning(for difficulty: Difficulty) -> DifficultyTuning {
        switch difficulty {
        case .easy:
            return DifficultyTuning(reactionTime: 0.55, aimError: 70, abilityChance: 0.25, minCastGap: 4.0,
                                    retreatHp: 0.22, dodgeChance: 0.25, gankInterval: 150,
                                    enemyGoldMultiplier: 0.8, tradeAdvantage: 0.25)
        case .normal:
            return DifficultyTuning(reactionTime: 0.3, aimError: 35, abilityChance: 0.5, minCastGap: 2.2,
                                    retreatHp: 0.3, dodgeChance: 0.65, gankInterval: 95,
                                    enemyGoldMultiplier: 1.0, tradeAdvantage: 0.1)
        case .hard:
            return DifficultyTuning(reactionTime: 0.15, aimError: 12, abilityChance: 0.8, minCastGap: 1.2,
                                    retreatHp: 0.35, dodgeChance: 0.95, gankInterval: 65,
                                    enemyGoldMultiplier: 1.2, tradeAdvantage: 0.0)
        }
    }

    /// Radius in which the AI looks for enemies / allies.
    static let awarenessRadius: CGFloat = 950
    /// Distance the AI keeps behind its lane front.
    static let laneFrontOffset: CGFloat = 140
    /// Maximum seconds spent in a trade before re-evaluating.
    static let tradeDuration: CGFloat = 5
    /// Maximum seconds spent on a gank.
    static let gankDuration: CGFloat = 25
    /// Maximum seconds spent on an objective.
    static let objectiveDuration: CGFloat = 35
    /// Snap radius used by AI to consider a cluster of enemies.
    static let clusterRadius: CGFloat = 160
}

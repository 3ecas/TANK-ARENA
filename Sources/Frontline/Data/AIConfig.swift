import CoreGraphics

/// Bot tuning ("medium-hard"): quick reactions, decent aim, uses grenades.
enum AIConfig {
    static let thinkInterval: CGFloat = 0.18
    /// Delay between spotting a new enemy and opening fire.
    static let reactionTime: CGFloat = 0.3
    /// Aim error in points: base + per point of distance.
    static let aimErrorBase: CGFloat = 12
    static let aimErrorPerDistance: CGFloat = 0.035
    /// Radians per second bots can turn their aim.
    static let turnRate: CGFloat = 9
    /// Bots only fire when their aim is within this angle of the target.
    static let fireAngleTolerance: CGFloat = 0.12
    /// Chance per think step to throw a grenade when a good opportunity exists.
    static let grenadeChance: CGFloat = 0.22
    static let grenadeMinDistance: CGFloat = 170
    /// How long bots remember where they last saw an enemy.
    static let huntMemory: CGFloat = 4
    static let strafeIntervalMin: CGFloat = 0.5
    static let strafeIntervalMax: CGFloat = 1.3
    /// Bots try to fight at this fraction of their weapon range.
    static let preferredRangeFraction: CGFloat = 0.55
    /// Extra radians outside an enemy's view cone before a bot treats it as having its back turned.
    static let unawareMargin: CGFloat = 0.15
    /// Visible enemies with their back turned count as this many points closer when picking a target.
    static let exposedTargetBonus: CGFloat = 350
    /// Within this distance a bot sneaks up on an unaware enemy to backstab it; further away it shoots.
    static let backstabRange: CGFloat = 170
    /// Reload when the magazine falls below this fraction and nobody is in sight.
    static let reloadThreshold: CGFloat = 0.35

    // MARK: Squads & cover

    /// Seconds between control-zone objective reviews.
    static let objectiveInterval: CGFloat = 4
    static let squadSize = 5
    /// Squads with this many (or fewer) living members merge into the nearest squad.
    static let mergeThreshold = 2
    static let squadUpdateInterval: CGFloat = 0.4
    /// How long a squad remembers a contact report.
    static let contactMemory: CGFloat = 6
    /// How long a bot stays in combat mode after last seeing an enemy.
    static let combatMemory: CGFloat = 3.5
    /// Idle squads within this distance of another squad's fight come to help.
    static let supportRadius: CGFloat = 1100
    /// Members further than this from the leader make it wait (unless they are very far, e.g. respawning).
    static let gatherRadius: CGFloat = 240
    static let stragglerRadius: CGFloat = 900
    /// Strength ratio (allies / known enemies) needed to push, below which the squad falls back.
    static let pushRatio: CGFloat = 1.5
    static let retreatRatio: CGFloat = 0.75
    /// Squad average HP fraction below which it falls back.
    static let retreatHealth: CGFloat = 0.4
    /// Individual bots seek fallback cover below this HP fraction.
    static let lowHealth: CGFloat = 0.35
    /// How far bots look for cover.
    static let coverSearchRadius: CGFloat = 300
    static let fallbackSearchRadius: CGFloat = 480
    /// Preferred distance to the enemy when holding a position.
    static let holdDistance: CGFloat = 430
    static let fallbackDistance: CGFloat = 700
}

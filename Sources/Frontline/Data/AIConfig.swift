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

    /// Lone flankers per team that circle around the map to hit the enemy from behind.
    static let roguesPerTeam = 1
    /// Rush has bigger teams, so more lone flankers.
    static let rushRogues = 3
    /// How far from the top / bottom edge flanking routes run.
    static let flankEdgeMargin: CGFloat = 170
    /// Squads only flank when the objective is at least this far away horizontally.
    static let flankMinDistance: CGFloat = 600
    static let flankReachedDistance: CGFloat = 150
    /// Seconds before an unreached flank point or rogue waypoint is abandoned.
    static let flankTimeout: CGFloat = 25
    static let waypointTimeout: CGFloat = 20
    /// Rogues aim for a point this far behind the enemy front line.
    static let rogueBehindDistance: CGFloat = 320
    // MARK: Doorways, prediction and room clearing

    /// Doorway detection: probe spacing, max opening width, width that counts as a room, probe distance, merge radius.
    static let chokeProbeStep: CGFloat = 20
    static let chokeMaxWidth: CGFloat = 140
    static let chokeOpenWidth: CGFloat = 260
    static let chokeLookAhead: CGFloat = 60
    static let chokeMergeRadius: CGFloat = 90
    /// How long a shared enemy sighting is remembered, and how far ahead (seconds) its movement is extrapolated.
    static let intelMemory: CGFloat = 8
    static let predictionHorizon: CGFloat = 1.5
    /// Idle bots watch openings within this distance, switching every `watchSwitchTime` seconds.
    static let watchRange: CGFloat = 700
    static let watchSwitchTime: CGFloat = 3
    /// Moving bots glance at openings they pass within this distance.
    static let glanceRange: CGFloat = 260
    /// Squads stack up on a doorway this far ahead on their path, this far from it, and hold before entering.
    static let stackLookAhead: CGFloat = 320
    static let stackDistance: CGFloat = 100
    static let stackHold: ClosedRange<CGFloat> = 1.0...1.8
    static let stackMaxWait: CGFloat = 4
    /// Rush: the nearest free attacker within this distance of an idle station goes to arm it.
    static let armReach: CGFloat = 600
    /// Team pushes: staging point this far before the site, radius that counts as "arrived", share of the
    /// team that must have arrived, max wait (attack / retake), retake hurries when the fuse is under this,
    /// chance each bot opens with its grenade, and how long squads skip door-stacking after going in.
    static let stageDistance: CGFloat = 520
    static let stageRadius: CGFloat = 260
    static let gatherFraction: CGFloat = 0.7
    static let gatherTimeout: CGFloat = 16
    static let retakeGatherTimeout: CGFloat = 7
    static let retakeHurry: CGFloat = 22
    static let executeUtilityChance: CGFloat = 0.6
    static let executeRushTime: CGFloat = 12
    /// Smarter objective play: enemies carrying / arming / defusing count this much closer as targets;
    /// defenders hold entrances within `siteDoorRange` of their site, `doorHoldDistance` inside them;
    /// the nearest free defender within `antiArmReach` runs to a station being armed;
    /// rush attackers regroup when fewer than `waveMinimum` of them are near the target `waveTimeout` s after going in.
    static let objectiveTargetBonus: CGFloat = 400
    static let siteDoorRange: CGFloat = 420
    static let doorHoldDistance: CGFloat = 110
    static let antiArmReach: CGFloat = 900
    static let waveTimeout: CGFloat = 14
    static let waveMinimum = 3
    /// Chance a squad just pushes through a doorway without stacking (always when time is short).
    static let rushChance: CGFloat = 0.3
    static let rushTimeLeft: CGFloat = 35
    /// A doorway the squad has cleared is not stacked on again for this long.
    static let clearedMemory: CGFloat = 25
    /// Seconds between control-zone objective reviews.
    static let objectiveInterval: CGFloat = 4
    static let squadSize = 5
    /// Defenders split into pairs so both sites are covered.
    static let defenderSquadSize = 2
    /// Squads with this many (or fewer) living members merge into the nearest squad.
    static let mergeThreshold = 1
    static let squadUpdateInterval: CGFloat = 0.4
    /// How long a squad remembers a contact report.
    static let contactMemory: CGFloat = 6
    /// How long a bot stays in combat mode after last seeing an enemy.
    static let combatMemory: CGFloat = 3.5
    /// Idle squads within this distance of another squad's fight come to help.
    static let supportRadius: CGFloat = 1500
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

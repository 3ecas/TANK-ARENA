import CoreGraphics

/// Drives one AI hero through a state machine. It only writes intent on the hero
/// (move direction, aim, target) and requests casts / purchases through the shared services.
@MainActor
final class HeroAIController {
    let hero: Hero
    let entry: RosterEntry
    unowned let ctx: GameContext
    let perception: AIPerception
    let shopper: AIShopper
    private let abilityUser: AIAbilityUser
    private let dodge: AIDodge
    private let states: [HeroAIStateKind: HeroAIState]

    private(set) var stateKind: HeroAIStateKind = .shopping
    private(set) var stateTime: CGFloat = 0
    private var thinkTimer: CGFloat = 0

    // Blackboard shared by states
    var moveGoal: CGPoint?
    var lane: Lane
    var lastGankTime: CGFloat = 0
    var gankTargetId: Int?
    var objective: AIObjectiveGoal?

    var tuning: DifficultyTuning { ctx.tuning }
    var world: GameWorld { ctx.world }
    var isInBase: Bool { world.map.isInBase(hero.position, team: hero.team) }

    init(hero: Hero, entry: RosterEntry, ctx: GameContext) {
        self.hero = hero
        self.entry = entry
        self.ctx = ctx
        self.lane = entry.lane
        self.perception = AIPerception(hero: hero, ctx: ctx)
        self.shopper = AIShopper(hero: hero, build: entry.build, ctx: ctx)
        self.abilityUser = AIAbilityUser(hero: hero, ctx: ctx)
        self.dodge = AIDodge(hero: hero, ctx: ctx)
        self.states = [
            .dead: DeadState(), .shopping: ShoppingState(), .laning: LaningState(), .trading: TradingState(),
            .retreating: RetreatState(), .recalling: RecallState(), .ganking: GankState(),
            .objective: ObjectiveState(),
        ]
        StatCalculator.apply(to: hero)
        lastGankTime = CGFloat.random(in: 0...30)
    }

    func update(dt: CGFloat) {
        stateTime += dt
        guard hero.isAlive else {
            if stateKind != .dead { switchTo(.dead) }
            hero.moveDir = .zero
            hero.targetId = nil
            return
        }
        thinkTimer -= dt
        if thinkTimer <= 0 {
            thinkTimer = tuning.reactionTime * CGFloat.random(in: 0.8...1.2)
            think()
        }
        steer()
    }

    func switchTo(_ kind: HeroAIStateKind) {
        stateKind = kind
        stateTime = 0
        moveGoal = nil
        states[kind]?.enter(self)
    }

    private func think() {
        perception.refresh()
        if let forced = globalTransition() { switchTo(forced) }
        if let next = states[stateKind]?.think(self), next != stateKind { switchTo(next) }
        abilityUser.consider(state: stateKind, goal: moveGoal)
        shopper.spendAbilityPoints()
    }

    private func globalTransition() -> HeroAIStateKind? {
        if stateKind == .dead { return .shopping }
        let busy = stateKind == .retreating || stateKind == .recalling || stateKind == .shopping
        if !busy && !isInBase && hero.hpFraction < tuning.retreatHp { return .retreating }
        return nil
    }

    /// Hands the chosen destination to the shared hero movement (pathfinding) system.
    private func steer() {
        hero.chasesTarget = false
        if let escape = dodge.escapeDirection() {
            let escapePoint = hero.position + escape * 160
            hero.moveGoal = world.nav.nearestWalkable(escapePoint)
            if ctx.difficulty != .easy { DodgeRoll.perform(hero, toward: escapePoint) }
        } else if let goal = moveGoal, hero.position.distance(to: goal) > 14 {
            hero.moveGoal = goal
        } else {
            hero.moveGoal = nil
        }
        if let target = world.entity(hero.targetId) {
            hero.aimPoint = target.position
        } else if let goal = hero.moveGoal {
            hero.aimPoint = goal
        }
    }

    // MARK: Helpers used by states

    /// Moves a goal out of the range of enemy structures that are not busy with allied troops.
    func safePoint(_ goal: CGPoint) -> CGPoint {
        guard let structure = perception.dangerousStructure(at: goal), !perception.isTanked(structure),
              let range = structure.attack?.range else { return goal }
        let away = (goal - structure.position).lengthSquared > 1
            ? (goal - structure.position).normalized
            : (hero.spawnPoint - structure.position).normalized
        return structure.position + away * (range + hero.radius + 60)
    }

    /// Position at weapon range from `target`, on our side.
    func attackPosition(for target: Entity, rangeFactor: CGFloat = 0.85) -> CGPoint {
        let away = (hero.position - target.position).lengthSquared > 1
            ? (hero.position - target.position).normalized
            : (hero.spawnPoint - target.position).normalized
        return target.position + away * (hero.stats.range * rangeFactor + target.radius)
    }

    func canAttack(_ target: Entity) -> Bool {
        ctx.targeting.canTarget(hero, target)
    }
}

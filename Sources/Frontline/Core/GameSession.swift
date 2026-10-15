import CoreGraphics

/// One match: builds the world and runs every system in a fixed order each frame.
@MainActor
final class GameSession {
    let settings: GameSettings
    let world: GameWorld
    let bus: EventBus
    let ctx: GameContext
    let player: Hero
    let score: ScoreSystem
    private(set) var heroAIs: [HeroAIController] = []

    private let brains: BrainSystem
    private let movement: MovementSystem
    private let collision: CollisionSystem
    private let statusEffects: StatusEffectSystem
    private let health: HealthSystem
    private let autoAttack: AutoAttackSystem
    private let projectiles: ProjectileSystem
    private let death: DeathSystem
    private let spawner: SpawnSystem
    private let camps: NeutralCampSystem
    private let structures: StructureSystem
    private let winCondition: WinConditionSystem

    init(settings: GameSettings) {
        self.settings = settings
        let world = GameWorld()
        let bus = EventBus()
        let ctx = GameContext(world: world, bus: bus, difficulty: settings.difficulty)
        self.world = world
        self.bus = bus
        self.ctx = ctx
        ctx.targeting = TargetingSystem(ctx: ctx)
        ctx.vision = VisionSystem(ctx: ctx)
        ctx.damage = DamageSystem(ctx: ctx)
        ctx.combat = CombatSystem(ctx: ctx)
        ctx.strikes = StrikeSystem(ctx: ctx)
        ctx.zones = ZoneSystem(ctx: ctx)
        ctx.summons = SummonController(ctx: ctx)
        ctx.abilities = AbilitySystem(ctx: ctx)
        ctx.shop = ShopService(ctx: ctx)
        ctx.recall = RecallSystem(ctx: ctx)
        ctx.experience = ExperienceSystem(ctx: ctx)
        ctx.economy = EconomySystem(ctx: ctx)
        ctx.commandPoints = CommandPointSystem(ctx: ctx)
        ctx.objectives = ObjectiveSystem(ctx: ctx)

        brains = BrainSystem(ctx: ctx)
        movement = MovementSystem(ctx: ctx)
        collision = CollisionSystem(ctx: ctx)
        statusEffects = StatusEffectSystem(ctx: ctx)
        health = HealthSystem(ctx: ctx)
        autoAttack = AutoAttackSystem(ctx: ctx)
        projectiles = ProjectileSystem(ctx: ctx)
        death = DeathSystem(ctx: ctx)
        spawner = SpawnSystem(ctx: ctx)
        camps = NeutralCampSystem(ctx: ctx)
        structures = StructureSystem(ctx: ctx)
        winCondition = WinConditionSystem(ctx: ctx)
        score = ScoreSystem(ctx: ctx)

        MatchSetup.buildStructures(ctx: ctx)
        player = MatchSetup.makePlayer(ctx: ctx, loadout: settings.startingLoadout)
        heroAIs = MatchSetup.makeAIHeroes(ctx: ctx)
        world.grid.rebuild(with: world.entities)
        ctx.vision.recompute()
    }

    func update(dt: CGFloat) {
        guard world.winner == nil, dt > 0 else { return }
        world.time += dt
        world.grid.rebuild(with: world.entities)

        for ai in heroAIs { ai.update(dt: dt) }
        brains.update(dt: dt)
        ctx.abilities.update(dt: dt)
        statusEffects.update(dt: dt)
        movement.update(dt: dt)
        collision.update()
        world.grid.rebuild(with: world.entities)

        autoAttack.update(dt: dt)
        ctx.combat.update(dt: dt)
        projectiles.update(dt: dt)
        ctx.strikes.update(dt: dt)
        ctx.zones.update(dt: dt)
        health.update(dt: dt)
        ctx.recall.update(dt: dt)
        ctx.summons.update(dt: dt)

        spawner.update(dt: dt)
        camps.update(dt: dt)
        ctx.objectives.update(dt: dt)
        structures.update()
        ctx.economy.update(dt: dt)
        ctx.commandPoints.update(dt: dt)
        ctx.vision.update(dt: dt)
        death.update(dt: dt)
        world.purge()
    }

    func aiState(for hero: Hero) -> HeroAIStateKind? {
        heroAIs.first { $0.hero === hero }?.stateKind
    }
}

/// Shared services for one match. Systems keep an unowned reference to it.
/// Services are assigned right after creation by `GameSession` (hence the implicitly unwrapped optionals).
@MainActor
final class GameContext {
    let world: GameWorld
    let bus: EventBus
    let difficulty: Difficulty
    let tuning: DifficultyTuning
    let factory: EntityFactory

    var targeting: TargetingSystem!
    var vision: VisionSystem!
    var damage: DamageSystem!
    var combat: CombatSystem!
    var strikes: StrikeSystem!
    var zones: ZoneSystem!
    var summons: SummonController!
    var abilities: AbilitySystem!
    var shop: ShopService!
    var recall: RecallSystem!
    var economy: EconomySystem!
    var experience: ExperienceSystem!
    var commandPoints: CommandPointSystem!
    var objectives: ObjectiveSystem!

    init(world: GameWorld, bus: EventBus, difficulty: Difficulty) {
        self.world = world
        self.bus = bus
        self.difficulty = difficulty
        self.tuning = AIConfig.tuning(for: difficulty)
        self.factory = EntityFactory(world: world)
    }
}

import CoreGraphics

/// One battle: builds the world and runs every system in a fixed order each frame.
@MainActor
final class GameSession {
    let world: BattleWorld
    let bus: EventBus
    let ctx: BattleContext
    let player: Soldier
    let vision: VisionSystem
    let weapons: WeaponSystem
    let grenades: GrenadeSystem
    let melee: MeleeSystem
    private let movement: MovementSystem
    private let status: StatusSystem
    private let respawns: RespawnSystem
    private let match: MatchSystem
    let bombSystem: BombSystem
    private var bots: [SoldierAI] = []
    private var squads: SquadCoordinator?

    /// The player is always on blue; `playerAttacks` decides whether blue attacks or defends.
    init(map: MapKind, playerAttacks: Bool) {
        let world = BattleWorld(layout: MapLayout.make(map), attackers: playerAttacks ? .blue : .red)
        let bus = EventBus()
        let ctx = BattleContext(world: world, bus: bus)
        let damage = DamageSystem(ctx: ctx)
        self.world = world
        self.bus = bus
        self.ctx = ctx
        vision = VisionSystem(ctx: ctx)
        weapons = WeaponSystem(ctx: ctx, damage: damage)
        grenades = GrenadeSystem(ctx: ctx, damage: damage)
        melee = MeleeSystem(ctx: ctx, damage: damage)
        movement = MovementSystem(ctx: ctx)
        status = StatusSystem(ctx: ctx)
        respawns = RespawnSystem(ctx: ctx)
        match = MatchSystem(ctx: ctx)
        bombSystem = BombSystem(ctx: ctx, damage: damage)

        BattleSetup.populate(world)
        guard let player = world.player else { fatalError("Battle has no player") }
        self.player = player
        let services = BotServices(vision: vision, weapons: weapons, grenades: grenades, melee: melee,
                                   cover: CoverFinder(map: world.map))
        bots = world.soldiers.filter { !$0.isPlayer }.map { SoldierAI(soldier: $0, ctx: ctx, services: services) }
        squads = SquadCoordinator(ctx: ctx, bots: bots)
    }

    /// The soldier whose eyes the player sees through (themselves, or a teammate when eliminated).
    var viewer: Soldier? {
        if player.isAlive { return player }
        return world.soldiers(of: player.team).first { $0.isAlive }
    }

    func update(dt: CGFloat) {
        guard world.result == nil, dt > 0 else { return }
        world.time += dt
        squads?.update(dt: dt)
        for bot in bots { bot.update(dt: dt) }
        bombSystem.update(dt: dt)
        status.update(dt: dt)
        movement.update(dt: dt)
        weapons.update(dt: dt)
        melee.update(dt: dt)
        grenades.update(dt: dt)
        respawns.update(dt: dt)
        vision.update(dt: dt, viewer: viewer)
        match.update(dt: dt)
        world.purge()
    }
}

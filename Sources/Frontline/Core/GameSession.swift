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
    private var bots: [SoldierAI] = []

    init() {
        let world = BattleWorld()
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

        BattleSetup.populate(world)
        guard let player = world.player else { fatalError("Battle has no player") }
        self.player = player
        let services = BotServices(vision: vision, weapons: weapons, grenades: grenades, melee: melee)
        for team in Team.playable {
            let teamBots = world.soldiers(of: team).filter { !$0.isPlayer }
            for (slot, soldier) in teamBots.enumerated() {
                let route = BattleSetup.routeIndex(for: slot, of: teamBots.count)
                bots.append(SoldierAI(soldier: soldier, ctx: ctx, services: services, routeIndex: route))
            }
        }
        bus.subscribe { [unowned self] event in
            if case .soldierRespawned(let id) = event {
                self.bots.first(where: { $0.soldier.id == id })?.onRespawn()
            }
        }
    }

    /// The soldier whose eyes the player sees through (themselves, or a teammate when eliminated).
    var viewer: Soldier? {
        if player.isAlive { return player }
        return world.soldiers(of: player.team).first { $0.isAlive }
    }

    func update(dt: CGFloat) {
        guard world.winner == nil, dt > 0 else { return }
        world.time += dt
        for bot in bots { bot.update(dt: dt) }
        status.update(dt: dt)
        movement.update(dt: dt)
        weapons.update(dt: dt)
        melee.update(dt: dt)
        grenades.update(dt: dt)
        respawns.update(dt: dt)
        vision.update(dt: dt, viewer: viewer)
        match.update()
        world.purge()
    }
}

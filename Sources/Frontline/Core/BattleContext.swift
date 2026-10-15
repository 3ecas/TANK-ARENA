/// Shared references for one battle, handed to every system.
@MainActor
final class BattleContext {
    let world: BattleWorld
    let bus: EventBus

    init(world: BattleWorld, bus: EventBus) {
        self.world = world
        self.bus = bus
    }
}

/// Synchronous publish/subscribe hub. Systems, UI, effects and audio communicate through it
/// instead of calling into each other.
@MainActor
final class EventBus {
    typealias Handler = (GameEvent) -> Void
    private var handlers: [Handler] = []

    func subscribe(_ handler: @escaping Handler) {
        handlers.append(handler)
    }

    func publish(_ event: GameEvent) {
        for handler in handlers {
            handler(event)
        }
    }

    func removeAll() {
        handlers.removeAll()
    }
}

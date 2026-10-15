import CoreGraphics

/// Line-of-sight checks: what bots can see, and which enemies are shown to the player.
@MainActor
final class VisionSystem {
    unowned let ctx: BattleContext
    /// Enemy ids currently visible from the viewer (the player, or the soldier being spectated).
    private(set) var visibleToViewer = Set<Int>()
    private var timer: CGFloat = 0

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat, viewer: Soldier?) {
        timer -= dt
        guard timer <= 0 else { return }
        timer = GameConfig.visionUpdateInterval
        var visible = Set<Int>()
        if let viewer = viewer, viewer.isAlive {
            for enemy in ctx.world.soldiers where enemy.isAlive && enemy.team != viewer.team && canSee(viewer, enemy) {
                visible.insert(enemy.id)
            }
        }
        visibleToViewer = visible
    }

    func canSee(_ viewer: Soldier, _ target: Soldier) -> Bool {
        guard !viewer.isBlind else { return false }
        return viewer.position.distance(to: target.position) <= GameConfig.visionRange
            && ctx.world.map.hasLineOfSight(viewer.position, target.position)
    }

    /// The closest enemy `viewer` can see, or nil.
    func nearestVisibleEnemy(for viewer: Soldier) -> Soldier? {
        guard !viewer.isBlind else { return nil }
        let candidates = ctx.world.soldiers
            .filter { $0.isAlive && $0.team != viewer.team
                && $0.position.distance(to: viewer.position) <= GameConfig.visionRange }
            .sorted { $0.position.distance(to: viewer.position) < $1.position.distance(to: viewer.position) }
        for enemy in candidates.prefix(6) where ctx.world.map.hasLineOfSight(viewer.position, enemy.position) {
            return enemy
        }
        return nil
    }
}

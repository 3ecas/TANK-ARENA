import CoreGraphics

/// Line-of-sight checks: what bots can see, and which enemies are shown to the player.
@MainActor
final class VisionSystem {
    unowned let ctx: BattleContext
    /// Enemy ids currently visible from the viewer (the player, or the soldier being spectated).
    private(set) var visibleToViewer = Set<Int>()

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    /// Recomputed every frame so the view cone follows the mouse smoothly.
    /// Only the viewer's own eyes count: enemies are shown only when the viewer can see them.
    func update(dt: CGFloat, viewer: Soldier?) {
        var visible = Set<Int>()
        if let viewer = viewer, viewer.isAlive {
            for enemy in ctx.world.soldiers where enemy.isAlive && enemy.team != viewer.team && canSee(viewer, enemy) {
                visible.insert(enemy.id)
            }
        }
        visibleToViewer = visible
    }

    /// Line of sight inside the viewer's field of view (or very close by).
    func canSee(_ viewer: Soldier, _ target: Soldier) -> Bool {
        guard !viewer.isBlind else { return false }
        let delta = target.position - viewer.position
        let distance = delta.length
        guard distance <= GameConfig.visionRange else { return false }
        if distance > GameConfig.peripheralRadius + target.radius {
            let halfFov = VisionSystem.fieldOfView(for: viewer) / 2
            guard abs(Angle.normalize(delta.angle - viewer.facing)) <= halfFov else { return false }
        }
        // Helicopters see and are seen over walls.
        if flies(viewer) || flies(target) { return true }
        return ctx.world.map.hasLineOfSight(viewer.position, target.position)
    }

    private func flies(_ soldier: Soldier) -> Bool {
        ctx.world.vehicle(of: soldier)?.flies == true
    }

    static func fieldOfView(for soldier: Soldier) -> CGFloat {
        GameConfig.fieldOfView
    }

    /// The closest enemy `viewer` can see, or nil.
    func nearestVisibleEnemy(for viewer: Soldier) -> Soldier? {
        visibleEnemies(for: viewer).first
    }

    /// Enemies `viewer` can see, closest first (only the closest few are checked).
    func visibleEnemies(for viewer: Soldier) -> [Soldier] {
        guard !viewer.isBlind else { return [] }
        let candidates = ctx.world.soldiers
            .filter { $0.isAlive && $0.team != viewer.team
                && $0.position.distance(to: viewer.position) <= GameConfig.visionRange }
            .sorted { $0.position.distance(to: viewer.position) < $1.position.distance(to: viewer.position) }
        return candidates.prefix(8).filter { canSee(viewer, $0) }
    }

    /// True when `target` cannot see `watcher`: it faces away (watcher outside its view cone), or it is blind or stunned.
    func isUnaware(_ target: Soldier, of watcher: Soldier) -> Bool {
        if target.isBlind || target.isStunned { return true }
        let toWatcher = watcher.position - target.position
        if toWatcher.length <= GameConfig.peripheralRadius + watcher.radius { return false }
        let halfFov = VisionSystem.fieldOfView(for: target) / 2
        return abs(Angle.normalize(toWatcher.angle - target.facing)) > halfFov + AIConfig.unawareMargin
    }
}

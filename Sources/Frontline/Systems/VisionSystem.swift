import CoreGraphics

/// Fog of war: per-team visibility grids recomputed a few times per second.
@MainActor
final class VisionSystem {
    unowned let ctx: GameContext
    private var grids: [VisionGrid]
    private var timer: CGFloat = 0
    /// Increments every recompute (renderers use it to refresh the fog texture).
    private(set) var revision = 0

    init(ctx: GameContext) {
        self.ctx = ctx
        let grid = VisionGrid(worldSize: MapConfig.size, cellSize: GameConfig.visionCellSize)
        grids = [grid, grid]
    }

    func update(dt: CGFloat) {
        timer -= dt
        guard timer <= 0 else { return }
        timer = GameConfig.visionUpdateInterval
        recompute()
    }

    func recompute() {
        let world = ctx.world
        for team in Team.playable {
            let index = team.rawValue
            grids[index].clear()
            let radar = ctx.objectives.hasRadar(team)
            let multiplier = radar ? ObjectiveConfig.radarSightMultiplier : 1
            for entity in world.entities where entity.team == team && entity.isAlive && !entity.isRemoved {
                grids[index].reveal(center: entity.position, radius: entity.sightRange * multiplier)
            }
            for zone in world.zones where zone.team == team && zone.kind == .uavReveal && zone.isActive {
                grids[index].reveal(center: zone.center, radius: zone.radius)
            }
            if radar, let point = world.capturePoint(.radar) {
                grids[index].reveal(center: point.position, radius: ObjectiveConfig.radarRevealRadius)
            }
        }
        revision += 1
    }

    func grid(for team: Team) -> VisionGrid {
        grids[team == .red ? 1 : 0]
    }

    func isVisible(_ point: CGPoint, to team: Team) -> Bool {
        team == .neutral ? true : grids[team.rawValue].isVisible(point)
    }

    /// Whether `team` can currently see `entity`.
    func canSee(_ team: Team, _ entity: Entity) -> Bool {
        if team == .neutral || entity.team == team { return true }
        if entity is Structure { return true }
        if ctx.zones.isConcealed(entity, from: team) { return false }
        return grids[team.rawValue].isVisible(entity.position)
    }
}

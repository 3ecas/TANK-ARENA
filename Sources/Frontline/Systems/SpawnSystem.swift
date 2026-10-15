import CoreGraphics

/// Sends troop waves down every lane and deploys riflemen from destroyed APCs.
@MainActor
final class SpawnSystem {
    private struct PendingSpawn {
        let kind: EntityKind
        let team: Team
        let lane: Lane
        let multiplier: CGFloat
        let time: CGFloat
    }

    unowned let ctx: GameContext
    private var waveTimer: CGFloat = WaveConfig.firstWaveTime
    private var waveNumber = 0
    private var pending: [PendingSpawn] = []

    init(ctx: GameContext) {
        self.ctx = ctx
        ctx.bus.subscribe { [unowned self] event in
            if case .killed(let victimId, _) = event, let vehicle = self.ctx.world.entity(victimId) as? Vehicle,
               vehicle.deploysOnDeath > 0 {
                self.deployFromAPC(vehicle)
            }
        }
    }

    func update(dt: CGFloat) {
        let world = ctx.world
        waveTimer -= dt
        if waveTimer <= 0 {
            waveTimer += WaveConfig.interval
            waveNumber += 1
            queueWave()
        }
        guard !pending.isEmpty else { return }
        let due = pending.filter { $0.time <= world.time }
        pending.removeAll { $0.time <= world.time }
        for spawn in due {
            ctx.factory.makeTroop(spawn.kind, team: spawn.team, path: world.map.path(spawn.lane, for: spawn.team),
                                  multiplier: spawn.multiplier)
        }
    }

    private func queueWave() {
        let world = ctx.world
        let scaling = 1 + WaveConfig.scalingPerFiveMinutes * (world.time / 300).rounded(.down)
        for team in Team.playable {
            for lane in Lane.allCases {
                let empowered = world.barracksDestroyed[team]?.contains(lane) ?? false
                let multiplier = scaling + (empowered ? StructureConfig.barracksDownStatBonus : 0)
                for (index, kind) in composition(empowered: empowered).enumerated() {
                    pending.append(PendingSpawn(kind: kind, team: team, lane: lane, multiplier: multiplier,
                                                time: world.time + CGFloat(index) * WaveConfig.spawnStagger))
                }
            }
        }
    }

    private func composition(empowered: Bool) -> [EntityKind] {
        let time = ctx.world.time
        var kinds = Array(repeating: EntityKind.rifleman, count: WaveConfig.riflemen)
        if time >= WaveConfig.lateGameTime { kinds.append(.rifleman) }
        kinds += Array(repeating: EntityKind.rocketSoldier, count: WaveConfig.rocketSoldiers + (empowered ? 1 : 0))
        if time >= WaveConfig.tankStartTime && waveNumber % WaveConfig.tankEvery == 0 {
            kinds.append(.tank)
        } else if time >= WaveConfig.apcStartTime && waveNumber % WaveConfig.apcEvery == 1 {
            kinds.append(.apc)
        }
        return kinds
    }

    private func deployFromAPC(_ apc: Vehicle) {
        guard let lanePath = (apc.brain as? LaneBrain)?.path else { return }
        for i in 0..<apc.deploysOnDeath {
            let offset = CGPoint(angle: CGFloat(i) * .pi, length: 20)
            let unit = ctx.factory.makeUnit(.rifleman, team: apc.team, at: apc.position + offset)
            unit.brain = LaneBrain(path: lanePath, startIndex: lanePath.nextWaypointIndex(from: unit.position))
        }
    }
}

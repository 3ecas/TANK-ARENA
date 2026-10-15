import CoreGraphics

/// Capturing control zones and awarding 1 point per second for each zone a team holds.
@MainActor
final class ZoneSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        let world = ctx.world
        for zone in world.zones {
            updateCapture(zone, dt: dt)
            if let owner = zone.owner, !world.suddenDeath {
                world.scores[owner, default: 0] += ZoneConfig.pointsPerSecond * dt
            }
        }
    }

    private func updateCapture(_ zone: ControlZone, dt: CGFloat) {
        var blue = 0
        var red = 0
        for soldier in ctx.world.soldiers where soldier.isAlive && zone.contains(soldier.position) {
            if soldier.team == .blue { blue += 1 } else if soldier.team == .red { red += 1 }
        }
        zone.isContested = blue > 0 && red > 0
        zone.capturingTeam = nil
        guard !zone.isContested else { return }
        let count = Swift.max(blue, red)
        guard count > 0 else { return }
        let team: Team = blue > 0 ? .blue : .red
        let rate = dt / ZoneConfig.captureTime * (1 + 0.15 * CGFloat(count - 1))
        let previousOwner = zone.owner
        if team == .blue {
            zone.progress = Swift.min(1, zone.progress + rate)
        } else {
            zone.progress = Swift.max(-1, zone.progress - rate)
        }
        if zone.progress < 1 && zone.progress > -1 && zone.owner != team { zone.capturingTeam = team }
        // Losing the zone once progress crosses the middle; capturing at the end.
        if let owner = previousOwner,
           (owner == .blue && zone.progress <= 0) || (owner == .red && zone.progress >= 0) {
            zone.owner = nil
        }
        if zone.progress >= 1 && zone.owner != .blue {
            capture(zone, by: .blue)
        } else if zone.progress <= -1 && zone.owner != .red {
            capture(zone, by: .red)
        }
    }

    private func capture(_ zone: ControlZone, by team: Team) {
        zone.owner = team
        ctx.bus.publish(.zoneCaptured(name: zone.name, team: team))
    }
}

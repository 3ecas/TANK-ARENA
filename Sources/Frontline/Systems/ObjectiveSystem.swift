import CoreGraphics

/// Radar Station and Airfield capture points.
@MainActor
final class ObjectiveSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
        ctx.world.capturePoints = [
            CapturePoint(kind: .radar, position: ObjectiveConfig.radarPosition, radius: ObjectiveConfig.captureRadius),
            CapturePoint(kind: .airfield, position: ObjectiveConfig.airfieldPosition,
                         radius: ObjectiveConfig.captureRadius),
        ]
    }

    func update(dt: CGFloat) {
        for point in ctx.world.capturePoints { updatePoint(point, dt: dt) }
    }

    func hasRadar(_ team: Team) -> Bool {
        ctx.world.capturePoint(.radar)?.owner == team
    }

    /// Multiplier applied to call-in cooldowns for heroes of `team`.
    func callInCooldownMultiplier(for team: Team) -> CGFloat {
        ctx.world.capturePoint(.airfield)?.owner == team ? ObjectiveConfig.airfieldCooldownMultiplier : 1
    }

    private func updatePoint(_ point: CapturePoint, dt: CGFloat) {
        var blue = 0
        var red = 0
        for hero in ctx.world.heroes where hero.isAlive && hero.position.distance(to: point.position) <= point.radius {
            if hero.team == .blue { blue += 1 } else if hero.team == .red { red += 1 }
        }
        point.capturingTeam = nil
        let rate = dt / ObjectiveConfig.captureTime
        if blue > 0 && red == 0 {
            point.capturingTeam = .blue
            point.progress = Swift.min(1, point.progress + rate * (1 + 0.25 * CGFloat(blue - 1)))
        } else if red > 0 && blue == 0 {
            point.capturingTeam = .red
            point.progress = Swift.max(-1, point.progress - rate * (1 + 0.25 * CGFloat(red - 1)))
        }

        if let owner = point.owner,
           (owner == .blue && point.progress <= 0) || (owner == .red && point.progress >= 0) {
            point.owner = nil
            ctx.bus.publish(.announcement(text: "\(point.kind.title) neutralised", team: owner.opponent))
        }
        if point.progress >= 1 && point.owner != .blue {
            capture(point, by: .blue)
        } else if point.progress <= -1 && point.owner != .red {
            capture(point, by: .red)
        }
    }

    private func capture(_ point: CapturePoint, by team: Team) {
        point.owner = team
        ctx.economy.grantTeamGold(team, EconomyConfig.objectiveGold)
        ctx.bus.publish(.objectiveCaptured(title: point.kind.title, team: team))
        ctx.bus.publish(.announcement(text: "\(team.displayName) team captured the \(point.kind.title)", team: team))
    }
}

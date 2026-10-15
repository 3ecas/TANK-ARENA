import CoreGraphics

/// Telegraphed call-ins: warning countdown, aircraft pass, then impacts.
@MainActor
final class StrikeSystem {
    unowned let ctx: GameContext
    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func schedule(_ strike: StrikeZone) {
        ctx.world.addStrike(strike)
        ctx.bus.publish(.strikeIncoming(team: strike.team, position: strike.shape.center))
    }

    func update(dt: CGFloat) {
        for strike in ctx.world.strikes where !strike.isDone {
            if strike.warningRemaining > 0 {
                strike.warningRemaining -= dt
                if strike.warningRemaining <= 0 { begin(strike) }
                continue
            }
            strike.impactTimer -= dt
            while strike.impactTimer <= 0 && strike.impactsDone < strike.impactCount {
                impact(strike, index: strike.impactsDone)
                strike.impactsDone += 1
                strike.impactTimer += strike.impactInterval
            }
            if strike.impactsDone >= strike.impactCount { strike.isDone = true }
        }
    }

    private func begin(_ strike: StrikeZone) {
        strike.warningRemaining = 0
        strike.impactTimer = 0
        let duration = CGFloat(strike.impactCount) * strike.impactInterval + 0.6
        switch (strike.kind, strike.shape) {
        case (.strafing, .line(let from, let to, _)):
            let dir = (to - from).normalized
            ctx.bus.publish(.aircraftPass(from: from - dir * 500, to: to + dir * 500, duration: duration, kind: .jet))
        case (.carpet, .circle(let center, let radius)):
            let dir = strike.direction
            ctx.bus.publish(.aircraftPass(from: center - dir * (radius + 700), to: center + dir * (radius + 700),
                                          duration: duration + 0.6, kind: .bomber))
        default:
            break
        }
    }

    private func impactPoint(_ strike: StrikeZone, index: Int) -> CGPoint {
        let jitter = CGPoint(x: CGFloat.random(in: -14...14), y: CGFloat.random(in: -14...14))
        switch strike.shape {
        case .line(let from, let to, _):
            let t = (CGFloat(index) + 0.5) / CGFloat(Swift.max(strike.impactCount, 1))
            return from.lerp(to: to, t: t) + jitter
        case .circle(let center, let radius):
            switch strike.kind {
            case .carpet:
                let count = Swift.max(strike.impactCount - 1, 1)
                let along = (CGFloat(index) / CGFloat(count) * 2 - 1) * radius * 0.85
                let lanes: [CGFloat] = [-0.55, 0, 0.55]
                let lateral = lanes[index % lanes.count] * radius
                return center + strike.direction * along + strike.direction.perpendicular * lateral + jitter
            case .emp:
                return center
            default:
                return Geometry.randomPoint(in: center, radius: radius * 0.85)
            }
        }
    }

    private func impact(_ strike: StrikeZone, index: Int) {
        let point = impactPoint(strike, index: index)
        let info = DamageInfo(amount: strike.damagePerImpact, sourceId: strike.ownerId, team: strike.team,
                              structureMultiplier: StrikeConfig.structureMultiplier)
        if strike.kind == .emp {
            let affected = ctx.world.grid.query(center: point, radius: strike.impactRadius)
            for entity in affected where entity.isAlive && strike.team.isHostile(to: entity.team) {
                if entity.kind.isMechanical {
                    entity.status.applyStun(duration: strike.effectDuration)
                } else {
                    entity.status.applySlow(StrikeConfig.empSlow, duration: strike.effectDuration)
                }
            }
            ctx.damage.applyArea(center: point, radius: strike.impactRadius, info: info)
            ctx.bus.publish(.empPulse(position: point, radius: strike.impactRadius))
            return
        }
        ctx.damage.applyArea(center: point, radius: strike.impactRadius, info: info, hitsAir: strike.kind == .strafing)
        let big = strike.kind != .strafing
        ctx.bus.publish(.explosion(position: point, radius: strike.impactRadius, big: big))
    }
}

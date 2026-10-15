import CoreGraphics

enum StrikeShape {
    case circle(center: CGPoint, radius: CGFloat)
    case line(from: CGPoint, to: CGPoint, width: CGFloat)

    var center: CGPoint {
        switch self {
        case .circle(let center, _): return center
        case .line(let from, let to, _): return from.lerp(to: to, t: 0.5)
        }
    }

    func contains(_ p: CGPoint, padding: CGFloat = 0) -> Bool {
        switch self {
        case .circle(let center, let radius):
            return p.distance(to: center) <= radius + padding
        case .line(let from, let to, let width):
            return Geometry.distance(from: p, toSegment: from, to) <= width / 2 + padding
        }
    }
}

enum StrikeKind {
    case strafing, carpet, artillery, emp
}

/// A telegraphed call-in: warning first, then one or more impacts.
@MainActor
final class StrikeZone {
    let id: Int
    let team: Team
    let ownerId: Int
    let kind: StrikeKind
    let shape: StrikeShape
    /// Direction the aircraft travel (carpet / strafing).
    let direction: CGPoint
    let totalWarning: CGFloat
    var warningRemaining: CGFloat
    let impactCount: Int
    let impactInterval: CGFloat
    let damagePerImpact: CGFloat
    let impactRadius: CGFloat
    /// EMP disable / slow duration.
    let effectDuration: CGFloat
    var impactsDone = 0
    var impactTimer: CGFloat = 0
    var isDone = false

    init(id: Int, team: Team, ownerId: Int, kind: StrikeKind, shape: StrikeShape, direction: CGPoint,
         warning: CGFloat, impactCount: Int, impactInterval: CGFloat, damagePerImpact: CGFloat,
         impactRadius: CGFloat, effectDuration: CGFloat = 0) {
        self.id = id
        self.team = team
        self.ownerId = ownerId
        self.kind = kind
        self.shape = shape
        self.direction = direction
        self.totalWarning = warning
        self.warningRemaining = warning
        self.impactCount = impactCount
        self.impactInterval = impactInterval
        self.damagePerImpact = damagePerImpact
        self.impactRadius = impactRadius
        self.effectDuration = effectDuration
    }

    var isWarning: Bool { warningRemaining > 0 }
    /// 0 when just called, 1 at impact.
    var warningProgress: CGFloat { 1 - (warningRemaining / Swift.max(totalWarning, 0.01)) }
}

import CoreGraphics

enum CapturePointKind {
    case radar, airfield

    var title: String {
        switch self {
        case .radar: return "Radar Station"
        case .airfield: return "Airfield"
        }
    }
}

/// A neutral capture objective. progress: -1 (red owned) ... +1 (blue owned).
@MainActor
final class CapturePoint {
    let kind: CapturePointKind
    let position: CGPoint
    let radius: CGFloat
    var progress: CGFloat = 0
    var owner: Team?
    /// Team currently standing alone on the point (for UI).
    var capturingTeam: Team?

    init(kind: CapturePointKind, position: CGPoint, radius: CGFloat) {
        self.kind = kind
        self.position = position
        self.radius = radius
    }
}

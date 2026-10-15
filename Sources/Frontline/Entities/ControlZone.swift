import CoreGraphics

/// A capture zone. progress goes from -1 (red owns) to +1 (blue owns).
@MainActor
final class ControlZone {
    let name: String
    let center: CGPoint
    let radius: CGFloat
    var progress: CGFloat = 0
    var owner: Team?
    /// Team currently capturing alone (nil when empty or contested).
    var capturingTeam: Team?
    var isContested = false

    init(name: String, center: CGPoint, radius: CGFloat) {
        self.name = name
        self.center = center
        self.radius = radius
    }

    func contains(_ point: CGPoint) -> Bool {
        point.distance(to: center) <= radius
    }
}

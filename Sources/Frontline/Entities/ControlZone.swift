import CoreGraphics

/// A capture zone. progress goes from -1 (red owns) to +1 (blue owns).
@MainActor
final class ControlZone {
    let name: String
    let center: CGPoint
    let radius: CGFloat
    /// Index of the sector this zone belongs to (0 = A).
    let sector: Int
    var progress: CGFloat = 0
    var owner: Team?
    /// Team currently capturing alone (nil when empty or contested).
    var capturingTeam: Team?
    var isContested = false

    init(name: String, center: CGPoint, radius: CGFloat, sector: Int, owner: Team) {
        self.name = name
        self.center = center
        self.radius = radius
        self.sector = sector
        self.owner = owner
        progress = owner == .blue ? 1 : -1
    }

    func contains(_ point: CGPoint) -> Bool {
        point.distance(to: center) <= radius
    }
}

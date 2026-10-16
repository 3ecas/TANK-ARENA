import CoreGraphics

/// A bomb site: the bomb can only be planted inside this circle.
@MainActor
final class BombSite {
    let name: String
    let center: CGPoint
    let radius: CGFloat

    init(name: String, center: CGPoint, radius: CGFloat) {
        self.name = name
        self.center = center
        self.radius = radius
    }

    func contains(_ point: CGPoint) -> Bool {
        point.distance(to: center) <= radius
    }
}

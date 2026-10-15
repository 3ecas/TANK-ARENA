import CoreGraphics

enum MapConfig {
    static let size: CGFloat = 4000
    static let blueHQ = CGPoint(x: 420, y: 420)
    static let blueSpawn = CGPoint(x: 190, y: 190)
    static let baseRadius: CGFloat = 760
    static let laneWidth: CGFloat = 190
    static let riverWidth: CGFloat = 280

    /// Lane waypoints from the blue base toward the red base (HQs are added automatically).
    static let blueLaneWaypoints: [Lane: [CGPoint]] = [
        .top: [CGPoint(x: 330, y: 800), CGPoint(x: 330, y: 3250),
               CGPoint(x: 750, y: 3670), CGPoint(x: 3200, y: 3670)],
        .mid: [CGPoint(x: 900, y: 900), CGPoint(x: 2000, y: 2000), CGPoint(x: 3100, y: 3100)],
        .bot: [CGPoint(x: 800, y: 330), CGPoint(x: 3250, y: 330),
               CGPoint(x: 3670, y: 750), CGPoint(x: 3670, y: 3200)],
    ]

    /// Point-mirror used to derive the red side from the blue side.
    static func mirror(_ p: CGPoint) -> CGPoint {
        CGPoint(x: size - p.x, y: size - p.y)
    }
}

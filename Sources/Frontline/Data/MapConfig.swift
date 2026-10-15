import CoreGraphics

/// Hand-made close-quarters arena. Only the left (blue) half is described; the red half is the
/// point-mirror, so the map is perfectly fair. Buildings and crates block movement and bullets.
enum MapConfig {
    static let size = CGSize(width: 2800, height: 1800)
    static let blueSpawn = CGRect(x: 40, y: 640, width: 220, height: 520)

    /// Buildings in the blue half (x, y, width, height). Alleys and streets are the gaps between them.
    static let blueBuildings: [CGRect] = [
        CGRect(x: 300, y: 1050, width: 450, height: 330),
        CGRect(x: 300, y: 1480, width: 450, height: 240),
        CGRect(x: 300, y: 420, width: 450, height: 330),
        CGRect(x: 300, y: 80, width: 450, height: 240),
        CGRect(x: 850, y: 1150, width: 300, height: 250),
        CGRect(x: 850, y: 1500, width: 380, height: 220),
        CGRect(x: 850, y: 400, width: 300, height: 250),
        CGRect(x: 850, y: 80, width: 380, height: 220),
        CGRect(x: 1250, y: 1250, width: 150, height: 160),
        CGRect(x: 1250, y: 390, width: 150, height: 160),
    ]

    /// Low cover (crates, barriers) in the blue half.
    static let blueCrates: [CGRect] = [
        CGRect(x: 520, y: 870, width: 48, height: 48),
        CGRect(x: 640, y: 960, width: 40, height: 70),
        CGRect(x: 520, y: 1405, width: 40, height: 40),
        CGRect(x: 520, y: 355, width: 40, height: 40),
        CGRect(x: 780, y: 1250, width: 40, height: 60),
        CGRect(x: 780, y: 490, width: 40, height: 60),
        CGRect(x: 1000, y: 820, width: 60, height: 40),
        CGRect(x: 1060, y: 940, width: 40, height: 60),
        CGRect(x: 1340, y: 870, width: 60, height: 60),
        CGRect(x: 1200, y: 1060, width: 50, height: 50),
        CGRect(x: 1200, y: 690, width: 50, height: 50),
    ]

    /// Attack routes for the blue team, from spawn toward the red spawn (red uses the mirror).
    static let blueRoutes: [[CGPoint]] = [
        [CGPoint(x: 280, y: 900), CGPoint(x: 800, y: 900), CGPoint(x: 1400, y: 980),
         CGPoint(x: 2000, y: 900), CGPoint(x: 2620, y: 900)],
        [CGPoint(x: 280, y: 1430), CGPoint(x: 800, y: 1440), CGPoint(x: 1400, y: 1455),
         CGPoint(x: 2000, y: 1440), CGPoint(x: 2520, y: 1430), CGPoint(x: 2640, y: 1000)],
        [CGPoint(x: 280, y: 370), CGPoint(x: 800, y: 360), CGPoint(x: 1400, y: 345),
         CGPoint(x: 2000, y: 360), CGPoint(x: 2520, y: 370), CGPoint(x: 2640, y: 800)],
        [CGPoint(x: 200, y: 1200), CGPoint(x: 280, y: 1760), CGPoint(x: 1400, y: 1760),
         CGPoint(x: 2520, y: 1760), CGPoint(x: 2640, y: 1150)],
        [CGPoint(x: 200, y: 600), CGPoint(x: 280, y: 40), CGPoint(x: 1400, y: 40),
         CGPoint(x: 2520, y: 40), CGPoint(x: 2640, y: 650)],
    ]

    /// Share of bots taking each route (main street, north alley, south alley, north edge, south edge).
    static let routeWeights: [CGFloat] = [0.36, 0.24, 0.24, 0.08, 0.08]

    static func mirror(_ p: CGPoint) -> CGPoint {
        CGPoint(x: size.width - p.x, y: size.height - p.y)
    }

    static func mirror(_ r: CGRect) -> CGRect {
        CGRect(x: size.width - r.maxX, y: size.height - r.maxY, width: r.width, height: r.height)
    }
}

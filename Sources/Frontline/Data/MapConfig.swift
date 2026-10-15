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

    /// Extra cover that is NOT mirrored, so the two halves are not identical:
    /// wrecked cars, a bus, sandbag walls and barricades (x, y, width, height).
    static let irregularBarriers: [CGRect] = [
        // Blue half
        CGRect(x: 900, y: 1060, width: 70, height: 36),
        CGRect(x: 420, y: 790, width: 20, height: 90),
        CGRect(x: 120, y: 300, width: 120, height: 30),
        CGRect(x: 1170, y: 560, width: 60, height: 30),
        // Red half
        CGRect(x: 1700, y: 960, width: 26, height: 120),
        CGRect(x: 1700, y: 1060, width: 90, height: 26),
        CGRect(x: 2250, y: 1000, width: 130, height: 40),
        CGRect(x: 2600, y: 1350, width: 50, height: 120),
        CGRect(x: 1560, y: 1150, width: 60, height: 60),
        CGRect(x: 2380, y: 520, width: 40, height: 80),
    ]

    static func mirror(_ p: CGPoint) -> CGPoint {
        CGPoint(x: size.width - p.x, y: size.height - p.y)
    }

    static func mirror(_ r: CGRect) -> CGRect {
        CGRect(x: size.width - r.maxX, y: size.height - r.maxY, width: r.width, height: r.height)
    }
}

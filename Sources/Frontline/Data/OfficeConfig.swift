import CoreGraphics

/// Tuning for the generated "Office" map: the floor is split again and again by walls at random
/// positions (recursive division), giving irregular rooms of every size joined by doorways.
enum OfficeConfig {
    static let wallThickness: CGFloat = 24
    static let outerWall: CGFloat = 40
    static let doorWidth: CGFloat = 110
    /// No room gets narrower than this.
    static let minRoom: CGFloat = 200
    /// Rooms smaller than `stopArea` stop splitting with this chance (keeps some big open rooms).
    static let stopChance: CGFloat = 0.3
    static let stopArea: CGFloat = 520 * 520
    /// Walls longer than this get two doorways.
    static let twoDoorSpan: CGFloat = 650
    /// Desks: area kept free along each room's walls, sizes, and clearance around a site centre.
    static let deskMargin: CGFloat = 70
    static let deskSizes: [CGSize] = [CGSize(width: 90, height: 44), CGSize(width: 44, height: 90),
                                      CGSize(width: 120, height: 44), CGSize(width: 60, height: 60)]
    /// Bomb sites are placed at random inside these areas each round (far apart: A upper right, B lower middle).
    static let siteAreas: [(name: String, area: CGRect)] = [
        ("A", CGRect(x: 1750, y: 1250, width: 300, height: 130)),
        ("B", CGRect(x: 1150, y: 200, width: 300, height: 130)),
    ]
}

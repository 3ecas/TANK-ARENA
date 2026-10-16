import CoreGraphics

/// How a generated office floor looks: size, spawns, where the sites go, and how it is cut into rooms
/// (recursive division: the floor is split by walls at random positions, each wall with doorways).
struct OfficeStyle {
    let size: CGSize
    let attackerSpawn: CGRect
    let defenderSpawn: CGRect
    /// Each site is placed at random inside its area every round.
    let siteAreas: [(name: String, area: CGRect)]
    /// No room gets narrower than this.
    let minRoom: CGFloat
    let doorWidth: CGFloat
    /// Walls longer than this get two doorways (three when twice as long).
    let doorSpan: CGFloat
    /// Rooms smaller than `stopArea` stop splitting with this chance (bigger value = bigger, simpler rooms).
    let stopChance: CGFloat
    let stopArea: CGFloat
    /// Max desks per room.
    let maxDesks: Int
}

enum OfficeConfig {
    static let wallThickness: CGFloat = 24
    static let outerWall: CGFloat = 40
    /// Desks keep this distance from walls (so doorways stay clear) and from site centres.
    static let deskMargin: CGFloat = 70
    static let deskSizes: [CGSize] = [CGSize(width: 90, height: 44), CGSize(width: 44, height: 90),
                                      CGSize(width: 120, height: 44), CGSize(width: 60, height: 60)]

    /// 5 vs 5 bomb: tight floor, small irregular rooms.
    static let bombStyle = OfficeStyle(
        size: CGSize(width: 2400, height: 1600),
        attackerSpawn: CGRect(x: 40, y: 600, width: 320, height: 400),
        defenderSpawn: CGRect(x: 2040, y: 640, width: 280, height: 320),
        siteAreas: [("A", CGRect(x: 1750, y: 1250, width: 300, height: 130)),
                    ("B", CGRect(x: 1150, y: 200, width: 300, height: 130))],
        minRoom: 200, doorWidth: 110, doorSpan: 650, stopChance: 0.3, stopArea: 520 * 520, maxDesks: 3)

    /// 16 vs 16 rush: a bigger, straightforward floor — large rooms, wide and frequent doorways.
    static let rushStyle = OfficeStyle(
        size: CGSize(width: 3600, height: 2200),
        attackerSpawn: CGRect(x: 60, y: 800, width: 380, height: 600),
        defenderSpawn: CGRect(x: 3160, y: 800, width: 380, height: 600),
        siteAreas: [("A", CGRect(x: 2350, y: 1650, width: 400, height: 200)),
                    ("B", CGRect(x: 2350, y: 350, width: 400, height: 200))],
        minRoom: 340, doorWidth: 170, doorSpan: 450, stopChance: 0.5, stopArea: 900 * 900, maxDesks: 2)
}

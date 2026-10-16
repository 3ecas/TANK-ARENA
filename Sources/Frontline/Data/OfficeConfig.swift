import CoreGraphics

/// Tuning for the generated "Office" map: a grid of rooms joined by doorways, with desks as cover.
enum OfficeConfig {
    /// Rooms are laid out on this grid (6 x 4 rooms of 400 x 400 on the 2400 x 1600 map).
    static let columns = 6
    static let rows = 4
    static let wallThickness: CGFloat = 24
    static let outerWall: CGFloat = 40
    static let doorWidth: CGFloat = 110
    /// Chance of an extra doorway on a wall that the generator's spanning tree did not already open.
    static let extraDoorChance: CGFloat = 0.4
    /// Desks per normal room, and their sizes.
    static let desksPerRoom: ClosedRange<Int> = 1...3
    static let deskSizes: [CGSize] = [CGSize(width: 90, height: 44), CGSize(width: 44, height: 90),
                                      CGSize(width: 120, height: 44), CGSize(width: 60, height: 60)]
    /// Bomb sites sit in the middle of a room so no wall cuts through them.
    static let sites: [ZoneConfig.ZoneSpec] = [
        ZoneConfig.ZoneSpec(name: "A", center: CGPoint(x: 1800, y: 1400)),
        ZoneConfig.ZoneSpec(name: "B", center: CGPoint(x: 1800, y: 200)),
    ]
    /// Desks keep this distance from the room's walls so doorways never get blocked.
    static let deskMargin: CGFloat = 80
}

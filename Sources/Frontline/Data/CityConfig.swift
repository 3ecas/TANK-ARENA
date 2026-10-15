import CoreGraphics

/// Tuning for the procedurally laid out city that fills the space between lanes.
enum CityConfig {
    static let seed: UInt64 = 1337
    /// Distance between the starts of two neighbouring city blocks.
    static let blockPitch: CGFloat = 180
    /// Width of the streets between blocks.
    static let streetWidth: CGFloat = 64
    /// Clearance kept free around lanes, river, bases and objectives.
    static let laneClearance: CGFloat = 45
    static let riverClearance: CGFloat = 40
    static let baseClearance: CGFloat = 40
    static let objectiveClearance: CGFloat = 250
    static let mapEdgeMargin: CGFloat = 24
    /// Fraction of blocks that become parks (walkable, no buildings).
    static let parkChance: CGFloat = 0.14
    /// Gap between buildings inside one block.
    static let buildingGap: CGFloat = 14
    /// Navigation grid resolution and the padding added around obstacles for unit size.
    static let navCellSize: CGFloat = 25
    static let navPadding: CGFloat = 12
}

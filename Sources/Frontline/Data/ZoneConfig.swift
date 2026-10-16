import CoreGraphics

/// Bomb site size.
enum ZoneConfig {
    struct ZoneSpec {
        let name: String
        let center: CGPoint
    }

    /// Radius of a bomb site (the bomb can only be planted inside it).
    static let radius: CGFloat = 130
}

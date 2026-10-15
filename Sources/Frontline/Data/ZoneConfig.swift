import CoreGraphics

/// Control zone size and capture speed.
enum ZoneConfig {
    struct ZoneSpec {
        let name: String
        let center: CGPoint
    }

    static let radius: CGFloat = 140
    /// Seconds for a lone team to capture a neutral zone (twice that to flip an enemy zone).
    static let captureTime: CGFloat = 4
}

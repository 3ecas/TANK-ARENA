import SpriteKit

/// Renders vector drawings into textures once and caches them.
@MainActor
enum TextureFactory {
    private static var cache: [String: SKTexture] = [:]
    /// Logical (point) size of every generated texture; pixel size differs on Retina renders.
    private static var pointSizes: [ObjectIdentifier: CGSize] = [:]

    static func size(of texture: SKTexture) -> CGSize {
        pointSizes[ObjectIdentifier(texture)] ?? texture.size()
    }

    /// A sprite showing `texture` at its logical size.
    static func sprite(_ texture: SKTexture) -> SKSpriteNode {
        SKSpriteNode(texture: texture, size: size(of: texture))
    }

    static func texture(_ key: String, size: CGSize, scale: CGFloat = 2,
                        draw: (CGContext, CGSize) -> Void) -> SKTexture {
        if let cached = cache[key] { return cached }
        let texture = render(size: size, scale: scale, draw: draw)
        cache[key] = texture
        return texture
    }

    static func render(size: CGSize, scale: CGFloat, draw: (CGContext, CGSize) -> Void) -> SKTexture {
        guard let image = renderImage(size: size, scale: scale, draw: draw) else { return SKTexture() }
        let texture = SKTexture(cgImage: image)
        pointSizes[ObjectIdentifier(texture)] = size
        return texture
    }

    static func renderImage(size: CGSize, scale: CGFloat, draw: (CGContext, CGSize) -> Void) -> CGImage? {
        let width = Swift.max(1, Int((size.width * scale).rounded()))
        let height = Swift.max(1, Int((size.height * scale).rounded()))
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.scaleBy(x: scale, y: scale)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        draw(context, size)
        return context.makeImage()
    }
}

/// Small drawing helpers on top of Core Graphics.
extension CGContext {
    func fillCircle(_ center: CGPoint, _ radius: CGFloat, _ color: CGColor) {
        setFillColor(color)
        fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }

    func strokeCircle(_ center: CGPoint, _ radius: CGFloat, _ color: CGColor, width: CGFloat) {
        setStrokeColor(color)
        setLineWidth(width)
        strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }

    func fillRoundedRect(_ rect: CGRect, radius: CGFloat, _ color: CGColor) {
        setFillColor(color)
        addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        fillPath()
    }

    func strokeRoundedRect(_ rect: CGRect, radius: CGFloat, _ color: CGColor, width: CGFloat) {
        setStrokeColor(color)
        setLineWidth(width)
        addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        strokePath()
    }

    func fillPolygon(_ points: [CGPoint], _ color: CGColor) {
        guard let first = points.first else { return }
        setFillColor(color)
        beginPath()
        move(to: first)
        for p in points.dropFirst() { addLine(to: p) }
        closePath()
        fillPath()
    }

    func strokeLine(_ from: CGPoint, _ to: CGPoint, _ color: CGColor, width: CGFloat) {
        setStrokeColor(color)
        setLineWidth(width)
        beginPath()
        move(to: from)
        addLine(to: to)
        strokePath()
    }

    func strokePolyline(_ points: [CGPoint], _ color: CGColor, width: CGFloat) {
        guard let first = points.first else { return }
        setStrokeColor(color)
        setLineWidth(width)
        beginPath()
        move(to: first)
        for p in points.dropFirst() { addLine(to: p) }
        strokePath()
    }

    /// Soft radial glow from `color` in the centre to transparent at `radius`.
    func fillRadialGlow(_ center: CGPoint, _ radius: CGFloat, _ color: CGColor) {
        let clear = color.copy(alpha: 0) ?? color
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: [color, clear] as CFArray, locations: [0, 1]) else { return }
        drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius,
                           options: [])
    }
}

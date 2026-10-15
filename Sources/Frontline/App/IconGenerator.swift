import AppKit

/// Draws the app icon in code (used for the Dock at runtime and for AppIcon.icns at build time).
@MainActor
enum IconGenerator {
    static func makeCGImage(size: CGFloat) -> CGImage? {
        TextureFactory.renderImage(size: CGSize(width: size, height: size), scale: 1) { ctx, canvas in
            draw(ctx, side: canvas.width)
        }
    }

    static func makeImage(size: CGFloat) -> NSImage? {
        guard let image = makeCGImage(size: size) else { return nil }
        return NSImage(cgImage: image, size: NSSize(width: size, height: size))
    }

    static func writePNG(to path: String, size: CGFloat) -> Bool {
        guard let image = makeCGImage(size: size) else { return false }
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else { return false }
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            return false
        }
    }

    private static func draw(_ ctx: CGContext, side s: CGFloat) {
        let inset = s * 0.09
        let rect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
        let corner = s * 0.18
        ctx.saveGState()
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil))
        ctx.clip()
        ctx.setFillColor(Palette.rgb(0.2, 0.27, 0.17))
        ctx.fill(rect)
        ctx.fillRadialGlow(CGPoint(x: s / 2, y: s / 2), s * 0.55, Palette.rgb(0.42, 0.5, 0.3, 0.9))
        // River and lanes
        ctx.strokeLine(CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.minY),
                       Palette.rgb(0.25, 0.45, 0.62), width: s * 0.07)
        let lane = Palette.rgb(0.72, 0.63, 0.45)
        let a = CGPoint(x: rect.minX + s * 0.14, y: rect.minY + s * 0.14)
        let b = CGPoint(x: rect.maxX - s * 0.14, y: rect.maxY - s * 0.14)
        ctx.strokePolyline([a, CGPoint(x: a.x, y: b.y), b], lane, width: s * 0.045)
        ctx.strokePolyline([a, CGPoint(x: b.x, y: a.y), b], lane, width: s * 0.045)
        ctx.strokeLine(a, b, lane, width: s * 0.045)
        ctx.fillCircle(a, s * 0.08, Palette.teamCG(.blue))
        ctx.fillCircle(b, s * 0.08, Palette.teamCG(.red))
        // Crosshair
        let c = CGPoint(x: s / 2, y: s / 2)
        let white = Palette.rgb(1, 1, 1, 0.95)
        ctx.strokeCircle(c, s * 0.17, white, width: s * 0.025)
        for i in 0..<4 {
            let angle = CGFloat(i) * .pi / 2
            ctx.strokeLine(c + CGPoint(angle: angle, length: s * 0.09), c + CGPoint(angle: angle, length: s * 0.26),
                           white, width: s * 0.025)
        }
        ctx.fillCircle(c, s * 0.025, Palette.rgb(1, 0.3, 0.2))
        ctx.restoreGState()
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil))
        ctx.setStrokeColor(Palette.rgb(0.08, 0.1, 0.07))
        ctx.setLineWidth(s * 0.015)
        ctx.strokePath()
    }
}

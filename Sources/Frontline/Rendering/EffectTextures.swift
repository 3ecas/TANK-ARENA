import SpriteKit

/// Generic shapes used by effects, telegraphs and UI (mostly white so they can be tinted).
@MainActor
enum EffectTextures {
    static var glow: SKTexture {
        TextureFactory.texture("glow", size: CGSize(width: 64, height: 64)) { ctx, size in
            ctx.fillRadialGlow(CGPoint(x: 32, y: 32), 32, Palette.rgb(1, 1, 1, 1))
        }
    }

    static var puff: SKTexture {
        TextureFactory.texture("puff", size: CGSize(width: 64, height: 64)) { ctx, size in
            ctx.fillRadialGlow(CGPoint(x: 32, y: 32), 31, Palette.rgb(1, 1, 1, 0.85))
            ctx.fillCircle(CGPoint(x: 26, y: 36), 12, Palette.rgb(1, 1, 1, 0.25))
        }
    }

    static var disc: SKTexture {
        TextureFactory.texture("disc", size: CGSize(width: 128, height: 128), scale: 1) { ctx, size in
            ctx.fillCircle(CGPoint(x: 64, y: 64), 63, Palette.rgb(1, 1, 1, 1))
        }
    }

    static var pixel: SKTexture {
        TextureFactory.texture("pixel", size: CGSize(width: 4, height: 4), scale: 1) { ctx, size in
            ctx.setFillColor(Palette.rgb(1, 1, 1, 1))
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    static var tracer: SKTexture {
        TextureFactory.texture("tracer", size: CGSize(width: 32, height: 4), scale: 1) { ctx, size in
            let colors = [Palette.rgb(1, 0.9, 0.5, 0), Palette.rgb(1, 0.95, 0.7, 1)] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: 0), options: [])
            }
        }
    }

    static var muzzleFlash: SKTexture {
        TextureFactory.texture("muzzle", size: CGSize(width: 24, height: 16)) { ctx, size in
            ctx.fillPolygon([CGPoint(x: 0, y: 8), CGPoint(x: 10, y: 15), CGPoint(x: 24, y: 8),
                             CGPoint(x: 10, y: 1)], Palette.rgb(1, 0.85, 0.35, 0.95))
            ctx.fillCircle(CGPoint(x: 8, y: 8), 4, Palette.rgb(1, 1, 0.9, 1))
        }
    }

    /// Ring outline with a constant line width for a given radius.
    static func ring(radius: CGFloat, lineWidth: CGFloat = 3) -> SKTexture {
        let r = Swift.max(8, (radius / 10).rounded() * 10)
        let side = r * 2 + lineWidth * 2
        return TextureFactory.texture("ring-\(Int(r))-\(Int(lineWidth))", size: CGSize(width: side, height: side),
                                      scale: 1) { ctx, size in
            ctx.strokeCircle(CGPoint(x: size.width / 2, y: size.height / 2), r, Palette.rgb(1, 1, 1, 1),
                             width: lineWidth)
        }
    }

    static var reticle: SKTexture {
        TextureFactory.texture("reticle", size: CGSize(width: 40, height: 40)) { ctx, size in
            let c = CGPoint(x: 20, y: 20)
            ctx.strokeCircle(c, 12, Palette.rgb(1, 1, 1, 1), width: 2)
            for i in 0..<4 {
                let a = CGFloat(i) * .pi / 2
                ctx.strokeLine(c + CGPoint(angle: a, length: 7), c + CGPoint(angle: a, length: 18),
                               Palette.rgb(1, 1, 1, 1), width: 2)
            }
        }
    }
}

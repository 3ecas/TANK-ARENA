import SpriteKit

/// Draws the city layer of the map: sidewalks, parks and rooftops with shadows and details.
@MainActor
enum CityPainter {
    private static let roofColors: [CGColor] = [
        Palette.rgb(0.55, 0.55, 0.53), Palette.rgb(0.47, 0.43, 0.38), Palette.rgb(0.38, 0.41, 0.45),
        Palette.rgb(0.58, 0.5, 0.4), Palette.rgb(0.42, 0.45, 0.4), Palette.rgb(0.5, 0.5, 0.56),
    ]

    static func drawSidewalks(_ ctx: CGContext, city: CityLayout) {
        for building in city.buildings {
            ctx.fillRoundedRect(building.rect.insetBy(dx: -10, dy: -10), radius: 6, Palette.rgb(0.4, 0.4, 0.39))
        }
    }

    static func drawParks(_ ctx: CGContext, city: CityLayout, rng: inout SeededRandom) {
        for park in city.parks {
            ctx.fillRoundedRect(park.insetBy(dx: -8, dy: -8), radius: 6, Palette.rgb(0.4, 0.4, 0.39))
            ctx.fillRoundedRect(park, radius: 10, Palette.rgb(0.26, 0.4, 0.22))
            ctx.strokeLine(CGPoint(x: park.minX, y: park.midY), CGPoint(x: park.maxX, y: park.midY),
                           Palette.rgb(0.6, 0.55, 0.42), width: 10)
            ctx.strokeLine(CGPoint(x: park.midX, y: park.minY), CGPoint(x: park.midX, y: park.maxY),
                           Palette.rgb(0.6, 0.55, 0.42), width: 10)
            for _ in 0..<9 {
                let p = CGPoint(x: park.minX + 18 + rng.next() * (park.width - 36),
                                y: park.minY + 18 + rng.next() * (park.height - 36))
                let r = 10 + rng.next() * 9
                ctx.fillCircle(p + CGPoint(x: 4, y: -4), r, Palette.rgb(0, 0, 0, 0.3))
                ctx.fillCircle(p, r, Palette.rgb(0.16, 0.32, 0.15))
                ctx.fillCircle(p + CGPoint(x: -3, y: 3), r * 0.5, Palette.rgb(0.25, 0.45, 0.22))
            }
        }
    }

    static func drawBuildings(_ ctx: CGContext, city: CityLayout, rng: inout SeededRandom) {
        for building in city.buildings {
            let rect = building.rect
            ctx.fillRoundedRect(rect.offsetBy(dx: 12, dy: -12), radius: 3, Palette.rgb(0, 0, 0, 0.45))
            let color = roofColors[building.style % roofColors.count]
            ctx.fillRoundedRect(rect, radius: 3, color)
            ctx.strokeRoundedRect(rect, radius: 3, Palette.rgb(0.1, 0.1, 0.1, 0.8), width: 4)
            let inner = rect.insetBy(dx: 9, dy: 9)
            if inner.width > 10 && inner.height > 10 {
                ctx.strokeRoundedRect(inner, radius: 2, Palette.rgb(1, 1, 1, 0.12), width: 3)
            }
            drawDetails(ctx, rect: inner, style: building.style, rng: &rng)
        }
    }

    private static func drawDetails(_ ctx: CGContext, rect: CGRect, style: Int, rng: inout SeededRandom) {
        guard rect.width > 30 && rect.height > 30 else { return }
        if style == 5 && rect.width > 90 && rect.height > 90 {
            let c = CGPoint(x: rect.midX, y: rect.midY)
            ctx.fillCircle(c, 30, Palette.rgb(0.25, 0.25, 0.27))
            ctx.strokeCircle(c, 30, Palette.rgb(0.9, 0.85, 0.3), width: 3)
            ctx.strokeLine(c + CGPoint(x: -10, y: -14), c + CGPoint(x: -10, y: 14), Palette.rgb(1, 1, 1, 0.9), width: 4)
            ctx.strokeLine(c + CGPoint(x: 10, y: -14), c + CGPoint(x: 10, y: 14), Palette.rgb(1, 1, 1, 0.9), width: 4)
            ctx.strokeLine(c + CGPoint(x: -10, y: 0), c + CGPoint(x: 10, y: 0), Palette.rgb(1, 1, 1, 0.9), width: 4)
            return
        }
        if style == 3 {
            let c = CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY + rect.height * 0.7)
            ctx.fillCircle(c, 14, Palette.rgb(0.35, 0.3, 0.25))
            ctx.strokeCircle(c, 14, Palette.rgb(0.2, 0.18, 0.15), width: 3)
        }
        let units = 1 + Int(rng.next() * 3)
        for _ in 0..<units {
            let w: CGFloat = 14 + rng.next() * 10
            let x = rect.minX + rng.next() * Swift.max(1, rect.width - w)
            let y = rect.minY + rng.next() * Swift.max(1, rect.height - w)
            ctx.fillRoundedRect(CGRect(x: x, y: y, width: w, height: w), radius: 2, Palette.rgb(0.68, 0.68, 0.66))
            ctx.strokeCircle(CGPoint(x: x + w / 2, y: y + w / 2), w * 0.3, Palette.rgb(0.3, 0.3, 0.3), width: 2)
        }
    }
}

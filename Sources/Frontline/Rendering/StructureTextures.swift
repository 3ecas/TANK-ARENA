import SpriteKit

/// Bunkers, barracks, HQ, supply crates.
@MainActor
enum StructureTextures {
    static func structure(kind: EntityKind, team: Team) -> SKTexture {
        switch kind {
        case .barracks: return barracks(team: team)
        case .hq: return hq(team: team)
        default: return bunker(team: team)
        }
    }

    static func bunker(team: Team) -> SKTexture {
        TextureFactory.texture("bunker-\(team.rawValue)", size: CGSize(width: 76, height: 76)) { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 0..<14 {
                let p = c + CGPoint(angle: CGFloat(i) * 2 * .pi / 14, length: 31)
                ctx.fillCircle(p, 6, Palette.sandbag)
                ctx.strokeCircle(p, 6, Palette.rgb(0.45, 0.4, 0.28), width: 1)
            }
            ctx.fillRoundedRect(CGRect(x: c.x - 22, y: c.y - 22, width: 44, height: 44), radius: 6, Palette.concrete)
            ctx.strokeRoundedRect(CGRect(x: c.x - 22, y: c.y - 22, width: 44, height: 44), radius: 6,
                                  Palette.concreteDark, width: 2)
            ctx.fillRoundedRect(CGRect(x: c.x - 14, y: c.y - 14, width: 28, height: 28), radius: 4, Palette.teamCG(team))
        }
    }

    static func barracks(team: Team) -> SKTexture {
        TextureFactory.texture("barracks-\(team.rawValue)", size: CGSize(width: 104, height: 80)) { ctx, size in
            let w = size.width, h = size.height
            ctx.fillRoundedRect(CGRect(x: 2, y: 2, width: w - 4, height: h - 4), radius: 6, Palette.concreteDark)
            ctx.fillRoundedRect(CGRect(x: 6, y: 6, width: w - 12, height: h - 12), radius: 4, Palette.teamDarkCG(team))
            for i in 0..<5 {
                let y = 12 + CGFloat(i) * (h - 24) / 4
                ctx.strokeLine(CGPoint(x: 10, y: y), CGPoint(x: w - 10, y: y), Palette.teamCG(team), width: 3)
            }
            ctx.fillRoundedRect(CGRect(x: w / 2 - 12, y: h / 2 - 12, width: 24, height: 24), radius: 3, Palette.concrete)
            ctx.fillPolygon([CGPoint(x: w / 2 - 6, y: h / 2 - 8), CGPoint(x: w / 2 + 9, y: h / 2),
                             CGPoint(x: w / 2 - 6, y: h / 2 + 8)], Palette.teamCG(team))
        }
    }

    static func hq(team: Team) -> SKTexture {
        TextureFactory.texture("hq-\(team.rawValue)", size: CGSize(width: 160, height: 160)) { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            var octagon: [CGPoint] = []
            for i in 0..<8 { octagon.append(c + CGPoint(angle: CGFloat(i) * .pi / 4 + .pi / 8, length: 76)) }
            ctx.fillPolygon(octagon, Palette.concreteDark)
            var inner: [CGPoint] = []
            for i in 0..<8 { inner.append(c + CGPoint(angle: CGFloat(i) * .pi / 4 + .pi / 8, length: 62)) }
            ctx.fillPolygon(inner, Palette.teamDarkCG(team))
            ctx.fillCircle(c, 40, Palette.teamCG(team))
            ctx.strokeCircle(c, 40, Palette.outline, width: 2)
            var star: [CGPoint] = []
            for i in 0..<10 {
                let radius: CGFloat = i % 2 == 0 ? 28 : 11
                star.append(c + CGPoint(angle: CGFloat(i) * .pi / 5 + .pi / 2, length: radius))
            }
            ctx.fillPolygon(star, Palette.rgb(1, 1, 1, 0.9))
        }
    }

    static func crate() -> SKTexture {
        TextureFactory.texture("crate", size: CGSize(width: 30, height: 30)) { ctx, size in
            let rect = CGRect(x: 2, y: 2, width: size.width - 4, height: size.height - 4)
            ctx.fillRoundedRect(rect, radius: 3, Palette.rgb(0.45, 0.5, 0.3))
            ctx.strokeRoundedRect(rect, radius: 3, Palette.rgb(0.25, 0.28, 0.15), width: 2)
            ctx.strokeLine(CGPoint(x: size.width / 2, y: 6), CGPoint(x: size.width / 2, y: size.height - 6),
                           Palette.rgb(1, 1, 1, 0.9), width: 4)
            ctx.strokeLine(CGPoint(x: 6, y: size.height / 2), CGPoint(x: size.width - 6, y: size.height / 2),
                           Palette.rgb(1, 1, 1, 0.9), width: 4)
        }
    }

    static func rubble() -> SKTexture {
        TextureFactory.texture("rubble", size: CGSize(width: 90, height: 90)) { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            ctx.fillRadialGlow(c, 44, Palette.rgb(0.1, 0.1, 0.1, 0.7))
            for i in 0..<12 {
                let p = c + CGPoint(angle: CGFloat(i) * 2.4, length: CGFloat(8 + (i * 7) % 26))
                ctx.fillCircle(p, CGFloat(3 + i % 4), Palette.rgb(0.35, 0.35, 0.33))
            }
        }
    }
}

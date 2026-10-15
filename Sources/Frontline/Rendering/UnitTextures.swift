import SpriteKit

/// Top-down soldier and vehicle sprites. All sprites face +x (angle 0).
@MainActor
enum UnitTextures {
    static func soldier(team: Team, hero: Bool, rocket: Bool = false) -> SKTexture {
        let side: CGFloat = hero ? 36 : 28
        let key = "soldier-\(team.rawValue)-\(hero)-\(rocket)"
        return TextureFactory.texture(key, size: CGSize(width: side, height: side)) { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = size.width * 0.27
            if hero { ctx.fillCircle(c, r + 4, Palette.rgb(1, 0.85, 0.3, 0.9)) }
            // Backpack
            ctx.fillRoundedRect(CGRect(x: c.x - r - 3, y: c.y - r * 0.6, width: r * 0.9, height: r * 1.2),
                                radius: 2, Palette.teamDarkCG(team))
            // Weapon
            if rocket {
                ctx.fillRoundedRect(CGRect(x: c.x - r * 0.6, y: c.y + r * 0.35, width: r * 2.6, height: r * 0.55),
                                    radius: 2, Palette.rgb(0.25, 0.3, 0.22))
            } else {
                ctx.fillRoundedRect(CGRect(x: c.x, y: c.y - r * 0.6, width: size.width / 2 - 1, height: r * 0.36),
                                    radius: 1, Palette.gunMetal)
            }
            // Shoulders / body
            ctx.fillCircle(c, r, Palette.teamCG(team))
            ctx.strokeCircle(c, r, Palette.outline, width: 1.2)
            // Helmet
            ctx.fillCircle(CGPoint(x: c.x + 1, y: c.y), r * 0.62, Palette.teamDarkCG(team))
            ctx.fillCircle(CGPoint(x: c.x + 2, y: c.y + 1), r * 0.25, Palette.rgb(1, 1, 1, 0.25))
        }
    }

    static func hull(kind: EntityKind, team: Team) -> SKTexture {
        let size: CGSize
        switch kind {
        case .superTank: size = CGSize(width: 86, height: 62)
        case .depotGuardian: size = CGSize(width: 96, height: 96)
        case .apc: size = CGSize(width: 56, height: 36)
        default: size = CGSize(width: 60, height: 44)
        }
        return TextureFactory.texture("hull-\(kind)-\(team.rawValue)", size: size) { ctx, size in
            let w = size.width, h = size.height
            if kind == .depotGuardian {
                drawMech(ctx, size: size, team: team)
                return
            }
            if kind == .apc {
                for i in 0..<3 {
                    let x = w * 0.18 + CGFloat(i) * w * 0.3
                    ctx.fillCircle(CGPoint(x: x, y: 4), 5, Palette.track)
                    ctx.fillCircle(CGPoint(x: x, y: h - 4), 5, Palette.track)
                }
                ctx.fillRoundedRect(CGRect(x: 2, y: 5, width: w - 4, height: h - 10), radius: 7, Palette.teamCG(team))
            } else {
                ctx.fillRoundedRect(CGRect(x: 0, y: 0, width: w, height: h * 0.24), radius: 3, Palette.track)
                ctx.fillRoundedRect(CGRect(x: 0, y: h * 0.76, width: w, height: h * 0.24), radius: 3, Palette.track)
                for i in stride(from: CGFloat(4), to: w, by: 7) {
                    ctx.strokeLine(CGPoint(x: i, y: 1), CGPoint(x: i, y: h * 0.22), Palette.rgb(0.3, 0.3, 0.3), width: 1.5)
                    ctx.strokeLine(CGPoint(x: i, y: h * 0.78), CGPoint(x: i, y: h - 1), Palette.rgb(0.3, 0.3, 0.3), width: 1.5)
                }
                ctx.fillRoundedRect(CGRect(x: 3, y: h * 0.17, width: w - 6, height: h * 0.66), radius: 5,
                                    Palette.teamCG(team))
            }
            ctx.strokeRoundedRect(CGRect(x: 3, y: h * 0.17, width: w - 6, height: h * 0.66), radius: 5,
                                  Palette.outline, width: 1.5)
            // Engine deck at the rear
            ctx.fillRoundedRect(CGRect(x: 6, y: h * 0.3, width: w * 0.2, height: h * 0.4), radius: 2,
                                Palette.teamDarkCG(team))
            ctx.fillCircle(CGPoint(x: w * 0.8, y: h * 0.5), 2.5, Palette.rgb(1, 1, 1, 0.35))
        }
    }

    static func turret(kind: EntityKind, team: Team) -> SKTexture {
        let big = kind == .superTank || kind == .depotGuardian
        let small = kind == .apc || kind == .sentry || kind == .helicopter
        let size = big ? CGSize(width: 96, height: 40) : (small ? CGSize(width: 40, height: 16) : CGSize(width: 66, height: 28))
        return TextureFactory.texture("turret-\(kind)-\(team.rawValue)", size: size) { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = size.height * (small ? 0.42 : 0.44)
            let barrel = size.height * (big ? 0.16 : 0.2)
            if big {
                ctx.fillRoundedRect(CGRect(x: c.x, y: c.y + 4, width: size.width / 2, height: barrel), radius: 2, Palette.gunMetal)
                ctx.fillRoundedRect(CGRect(x: c.x, y: c.y - 4 - barrel, width: size.width / 2, height: barrel), radius: 2, Palette.gunMetal)
            } else {
                ctx.fillRoundedRect(CGRect(x: c.x, y: c.y - barrel / 2, width: size.width / 2, height: barrel),
                                    radius: 2, Palette.gunMetal)
            }
            ctx.fillCircle(c, r, Palette.teamDarkCG(team))
            ctx.strokeCircle(c, r, Palette.outline, width: 1.2)
            ctx.fillCircle(CGPoint(x: c.x - r * 0.3, y: c.y + r * 0.3), r * 0.25, Palette.rgb(1, 1, 1, 0.2))
        }
    }

    static func helicopter(team: Team) -> SKTexture {
        TextureFactory.texture("heli-\(team.rawValue)", size: CGSize(width: 70, height: 30)) { ctx, size in
            let h = size.height
            ctx.fillRoundedRect(CGRect(x: 2, y: h / 2 - 2.5, width: 34, height: 5), radius: 2, Palette.teamDarkCG(team))
            ctx.fillRoundedRect(CGRect(x: 0, y: h / 2 - 7, width: 6, height: 14), radius: 2, Palette.teamDarkCG(team))
            ctx.setFillColor(Palette.teamCG(team))
            ctx.fillEllipse(in: CGRect(x: 26, y: h / 2 - 10, width: 40, height: 20))
            ctx.setFillColor(Palette.rgb(0.6, 0.85, 1, 0.8))
            ctx.fillEllipse(in: CGRect(x: 50, y: h / 2 - 6, width: 14, height: 12))
            ctx.fillRoundedRect(CGRect(x: 40, y: 2, width: 14, height: 4), radius: 1, Palette.gunMetal)
            ctx.fillRoundedRect(CGRect(x: 40, y: h - 6, width: 14, height: 4), radius: 1, Palette.gunMetal)
        }
    }

    static func rotor() -> SKTexture {
        TextureFactory.texture("rotor", size: CGSize(width: 72, height: 72)) { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            ctx.strokeCircle(c, 34, Palette.rgb(0.1, 0.1, 0.1, 0.18), width: 4)
            ctx.strokeLine(CGPoint(x: 2, y: c.y), CGPoint(x: size.width - 2, y: c.y), Palette.rgb(0.1, 0.1, 0.1, 0.85), width: 3)
            ctx.strokeLine(CGPoint(x: c.x, y: 2), CGPoint(x: c.x, y: size.height - 2), Palette.rgb(0.1, 0.1, 0.1, 0.85), width: 3)
            ctx.fillCircle(c, 4, Palette.gunMetal)
        }
    }

    static func aircraft(_ kind: AircraftPassKind) -> SKTexture {
        let size = kind == .bomber ? CGSize(width: 110, height: 90) : CGSize(width: 64, height: 50)
        return TextureFactory.texture("aircraft-\(kind)", size: size) { ctx, size in
            let w = size.width, h = size.height
            let body = Palette.rgb(0.45, 0.5, 0.48)
            ctx.fillPolygon([CGPoint(x: w * 0.55, y: h / 2), CGPoint(x: w * 0.15, y: h * 0.98),
                             CGPoint(x: w * 0.05, y: h * 0.98), CGPoint(x: w * 0.3, y: h / 2),
                             CGPoint(x: w * 0.05, y: h * 0.02), CGPoint(x: w * 0.15, y: h * 0.02)], body)
            ctx.fillRoundedRect(CGRect(x: 0, y: h / 2 - h * 0.07, width: w, height: h * 0.14), radius: h * 0.07, body)
            ctx.fillPolygon([CGPoint(x: w * 0.12, y: h / 2), CGPoint(x: 0, y: h * 0.72), CGPoint(x: 0, y: h * 0.28)], body)
            ctx.fillCircle(CGPoint(x: w * 0.82, y: h / 2), h * 0.05, Palette.rgb(0.6, 0.85, 1, 0.9))
        }
    }

    static func shadow(width: CGFloat, height: CGFloat) -> SKTexture {
        TextureFactory.texture("shadow-\(Int(width))x\(Int(height))", size: CGSize(width: width, height: height)) { ctx, size in
            ctx.setFillColor(Palette.rgb(0, 0, 0, 0.35))
            ctx.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
    }

    static func sentryBase(team: Team) -> SKTexture {
        TextureFactory.texture("sentry-\(team.rawValue)", size: CGSize(width: 30, height: 30)) { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 0..<3 {
                let a = CGFloat(i) * 2 * .pi / 3 + .pi / 2
                ctx.strokeLine(c, c + CGPoint(angle: a, length: 14), Palette.gunMetal, width: 3)
            }
            ctx.fillCircle(c, 7, Palette.teamCG(team))
        }
    }

    private static func drawMech(_ ctx: CGContext, size: CGSize, team: Team) {
        let c = CGPoint(x: size.width / 2, y: size.height / 2)
        let r = size.width * 0.38
        var hex: [CGPoint] = []
        for i in 0..<6 { hex.append(c + CGPoint(angle: CGFloat(i) * .pi / 3, length: r)) }
        ctx.fillRoundedRect(CGRect(x: c.x - 18, y: 2, width: 30, height: 16), radius: 4, Palette.track)
        ctx.fillRoundedRect(CGRect(x: c.x - 18, y: size.height - 18, width: 30, height: 16), radius: 4, Palette.track)
        ctx.fillPolygon(hex, Palette.teamCG(team))
        ctx.strokeCircle(c, r * 0.6, Palette.teamDarkCG(team), width: 5)
        ctx.fillCircle(c, r * 0.3, Palette.rgb(1, 0.4, 0.2, 0.9))
    }
}

import SpriteKit

/// Top-down soldier sprites (facing +x) for each team and weapon, plus grenade sprites.
@MainActor
enum SoldierTextures {
    static func soldier(team: Team, weapon: WeaponID) -> SKTexture {
        TextureFactory.texture("soldier-\(team.rawValue)-\(weapon)", size: CGSize(width: 40, height: 30)) { ctx, size in
            let c = CGPoint(x: 15, y: size.height / 2)
            let r: CGFloat = 9.5
            drawWeapon(ctx, weapon: weapon, center: c)
            // Shoulders and backpack
            ctx.fillRoundedRect(CGRect(x: c.x - r - 3, y: c.y - 6, width: 7, height: 12), radius: 2, Palette.teamDarkCG(team))
            ctx.setFillColor(Palette.teamCG(team))
            ctx.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r - 2, width: r * 2, height: r * 2 + 4))
            ctx.setStrokeColor(Palette.outline)
            ctx.setLineWidth(1.2)
            ctx.strokeEllipse(in: CGRect(x: c.x - r, y: c.y - r - 2, width: r * 2, height: r * 2 + 4))
            // Arms reaching to the weapon
            ctx.fillCircle(CGPoint(x: c.x + 7, y: c.y - 4), 3, Palette.skin)
            ctx.fillCircle(CGPoint(x: c.x + 10, y: c.y + 2), 3, Palette.skin)
            // Helmet
            ctx.fillCircle(c, 6.2, Palette.teamDarkCG(team))
            ctx.fillCircle(CGPoint(x: c.x + 1.5, y: c.y + 1.5), 2, Palette.rgb(1, 1, 1, 0.25))
        }
    }

    private static func drawWeapon(_ ctx: CGContext, weapon: WeaponID, center c: CGPoint) {
        let metal = Palette.gunMetal
        switch weapon {
        case .assaultRifle:
            ctx.fillRoundedRect(CGRect(x: c.x + 2, y: c.y - 3, width: 23, height: 4), radius: 1, metal)
            ctx.fillRoundedRect(CGRect(x: c.x + 8, y: c.y - 6, width: 4, height: 4), radius: 1, metal)
        case .smg:
            ctx.fillRoundedRect(CGRect(x: c.x + 3, y: c.y - 3, width: 16, height: 5), radius: 1, metal)
            ctx.fillRoundedRect(CGRect(x: c.x + 9, y: c.y - 7, width: 3, height: 5), radius: 1, metal)
        case .shotgun:
            ctx.fillRoundedRect(CGRect(x: c.x + 2, y: c.y - 3.5, width: 21, height: 6), radius: 2,
                                Palette.rgb(0.35, 0.24, 0.15))
            ctx.fillRoundedRect(CGRect(x: c.x + 12, y: c.y - 2.5, width: 12, height: 3), radius: 1, metal)
        case .pistol:
            ctx.fillRoundedRect(CGRect(x: c.x + 6, y: c.y - 2, width: 11, height: 4), radius: 1, metal)
        }
    }

    static func grenade(_ type: GrenadeType) -> SKTexture {
        TextureFactory.texture("grenade-\(type)", size: CGSize(width: 12, height: 12)) { ctx, size in
            let color: CGColor
            switch type {
            case .frag: color = Palette.rgb(0.3, 0.4, 0.22)
            case .flash: color = Palette.rgb(0.85, 0.85, 0.8)
            case .stun: color = Palette.rgb(0.3, 0.55, 0.85)
            }
            ctx.fillCircle(CGPoint(x: 6, y: 6), 5, color)
            ctx.strokeCircle(CGPoint(x: 6, y: 6), 5, Palette.outline, width: 1)
            ctx.fillRoundedRect(CGRect(x: 5, y: 9, width: 2, height: 3), radius: 1, Palette.gunMetal)
        }
    }

    static func bloodSplat() -> SKTexture {
        TextureFactory.texture("blood", size: CGSize(width: 40, height: 40)) { ctx, size in
            let c = CGPoint(x: 20, y: 20)
            ctx.fillRadialGlow(c, 18, Palette.rgb(0.45, 0.05, 0.05, 0.9))
            for i in 0..<6 {
                let p = c + CGPoint(angle: CGFloat(i) * 1.1, length: CGFloat(8 + (i * 5) % 9))
                ctx.fillCircle(p, CGFloat(2 + i % 3), Palette.rgb(0.4, 0.04, 0.04, 0.85))
            }
        }
    }

    /// Knife swipe arc (white, tinted at runtime).
    static func knifeArc() -> SKTexture {
        TextureFactory.texture("knife-arc", size: CGSize(width: 60, height: 60)) { ctx, size in
            ctx.setStrokeColor(Palette.rgb(1, 1, 1, 0.9))
            ctx.setLineWidth(4)
            ctx.addArc(center: CGPoint(x: 30, y: 30), radius: 24, startAngle: -0.8, endAngle: 0.8, clockwise: false)
            ctx.strokePath()
        }
    }
}

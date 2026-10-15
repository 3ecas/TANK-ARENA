import SpriteKit

/// Colours used by the renderer and UI.
@MainActor
enum Palette {
    static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
        CGColor(red: r, green: g, blue: b, alpha: a)
    }

    static func teamCG(_ team: Team) -> CGColor {
        switch team {
        case .blue: return rgb(0.22, 0.52, 0.95)
        case .red: return rgb(0.90, 0.26, 0.24)
        case .neutral: return rgb(0.85, 0.66, 0.25)
        }
    }

    static func teamDarkCG(_ team: Team) -> CGColor {
        switch team {
        case .blue: return rgb(0.10, 0.25, 0.50)
        case .red: return rgb(0.45, 0.10, 0.10)
        case .neutral: return rgb(0.42, 0.32, 0.12)
        }
    }

    static func team(_ team: Team) -> SKColor {
        SKColor(cgColor: teamCG(team)) ?? .white
    }

    static let player = SKColor(red: 0.35, green: 0.95, blue: 0.45, alpha: 1)
    static let gold = SKColor(red: 1.0, green: 0.84, blue: 0.3, alpha: 1)
    static let heal = SKColor(red: 0.45, green: 1.0, blue: 0.5, alpha: 1)
    static let damageTaken = SKColor(red: 1.0, green: 0.35, blue: 0.3, alpha: 1)
    static let commandPoints = SKColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1)
    static let warning = SKColor(red: 1.0, green: 0.25, blue: 0.15, alpha: 1)
    static let allyStrike = SKColor(red: 1.0, green: 0.65, blue: 0.15, alpha: 1)

    // Shared drawing colours
    static let gunMetal = rgb(0.16, 0.17, 0.18)
    static let outline = rgb(0.05, 0.06, 0.07, 0.9)
    static let skin = rgb(0.86, 0.70, 0.55)
    static let concrete = rgb(0.55, 0.56, 0.55)
    static let concreteDark = rgb(0.38, 0.39, 0.38)
    static let sandbag = rgb(0.72, 0.64, 0.45)
    static let track = rgb(0.12, 0.12, 0.12)
}

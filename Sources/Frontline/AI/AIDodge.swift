import CoreGraphics

/// Steps out of telegraphed enemy strike zones (depending on difficulty).
@MainActor
final class AIDodge {
    let hero: Hero
    unowned let ctx: GameContext
    private var decisions: [Int: Bool] = [:]

    init(hero: Hero, ctx: GameContext) {
        self.hero = hero
        self.ctx = ctx
    }

    func escapeDirection() -> CGPoint? {
        let strikes = ctx.world.strikes
        if decisions.count > 40 {
            let live = Set(strikes.map { $0.id })
            decisions = decisions.filter { live.contains($0.key) }
        }
        for strike in strikes where strike.team != hero.team && strike.isWarning {
            let willDodge: Bool
            if let decided = decisions[strike.id] {
                willDodge = decided
            } else {
                willDodge = CGFloat.random(in: 0...1) < ctx.tuning.dodgeChance
                decisions[strike.id] = willDodge
            }
            guard willDodge, strike.shape.contains(hero.position, padding: hero.radius + 30) else { continue }
            switch strike.shape {
            case .circle(let center, _):
                let away = hero.position - center
                return away.lengthSquared > 1 ? away.normalized : CGPoint(angle: CGFloat(hero.id))
            case .line(let from, let to, _):
                var side = (to - from).normalized.perpendicular
                if (hero.position - from).dot(side) < 0 { side = -side }
                return side
            }
        }
        return nil
    }
}

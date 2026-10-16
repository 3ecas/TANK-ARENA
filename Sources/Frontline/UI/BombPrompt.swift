import SpriteKit

/// Below the crosshair area: what the player can do with E right now (plant, arm, defuse),
/// and a progress bar while doing it.
@MainActor
final class BombPrompt {
    let root = SKNode()
    private let label = UIStyle.label("", size: 15, color: UIStyle.accent, bold: true, align: .center)
    private let barBack = UIStyle.rect(size: CGSize(width: 220, height: 10), color: SKColor(white: 0, alpha: 0.6))
    private let barFill = UIStyle.rect(size: CGSize(width: 220, height: 10), color: SKColor(red: 1, green: 0.6, blue: 0.15, alpha: 1))

    init() {
        label.position = CGPoint(x: 0, y: -150)
        barBack.position = CGPoint(x: 0, y: -172)
        barFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        barFill.position = CGPoint(x: -110, y: -172)
        for node in [label, barBack, barFill] { root.addChild(node) }
    }

    func update(world: BattleWorld, player: Soldier) {
        var text = ""
        var progress: CGFloat?
        if player.isAlive {
            for bomb in world.bombs {
                if let prompt = prompt(for: bomb, world: world, player: player) {
                    text = prompt.0
                    progress = prompt.1
                    break
                }
            }
        }
        label.text = text
        barBack.isHidden = progress == nil
        barFill.isHidden = progress == nil
        barFill.xScale = Swift.max(0, Swift.min(1, progress ?? 0))
    }

    private func prompt(for bomb: Bomb, world: BattleWorld, player: Soldier) -> (String, CGFloat?)? {
        let attacker = player.team == world.attackers
        let distance = player.position.distance(to: bomb.position)
        if bomb.carrierId == player.id {
            guard world.sites.contains(where: { $0.contains(player.position) }) else {
                return ("You have the bomb — take it to site A or B", nil)
            }
            return bomb.plantProgress > 0 ? ("PLANTING…", bomb.plantProgress) : ("Hold E to plant the bomb", nil)
        }
        if attacker && bomb.isIdle && distance <= BombConfig.armRadius {
            return bomb.plantProgress > 0 ? ("ARMING…", bomb.plantProgress) : ("Hold E to arm station \(bomb.site?.name ?? "")", nil)
        }
        if !attacker && bomb.isPlanted && distance <= BombConfig.defuseRadius {
            return bomb.defuserId == player.id ? ("DEFUSING…", bomb.defuseProgress) : ("Hold E to defuse", nil)
        }
        return nil
    }
}

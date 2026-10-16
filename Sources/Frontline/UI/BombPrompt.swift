import SpriteKit

/// Below the crosshair area: "Hold E to plant / defuse" when the player can, and a progress bar while doing it.
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
        let bomb = world.bomb
        var text = ""
        var progress: CGFloat?
        if player.isAlive {
            if bomb.carrierId == player.id {
                if world.sites.contains(where: { $0.contains(player.position) }) {
                    text = bomb.plantProgress > 0 ? "PLANTING…" : "Hold E to plant the bomb"
                    if bomb.plantProgress > 0 { progress = bomb.plantProgress }
                } else {
                    text = "You have the bomb — take it to site A or B"
                }
            } else if bomb.isPlanted && player.team == world.defenders
                        && player.position.distance(to: bomb.position) <= BombConfig.defuseRadius {
                text = bomb.defuserId == player.id ? "DEFUSING…" : "Hold E to defuse"
                if bomb.defuserId == player.id { progress = bomb.defuseProgress }
            }
        }
        label.text = text
        barBack.isHidden = progress == nil
        barFill.isHidden = progress == nil
        barFill.xScale = Swift.max(0, Swift.min(1, progress ?? 0))
    }
}

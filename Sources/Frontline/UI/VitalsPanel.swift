import SpriteKit

/// Bottom-left: health (100 max) and remaining respawns.
@MainActor
final class VitalsPanel {
    static let size = CGSize(width: 250, height: 74)
    let root = SKNode()
    private let barWidth: CGFloat = 226
    private let fill: SKSpriteNode
    private let hpLabel = UIStyle.label("", size: 26, bold: true)
    private let livesLabel = UIStyle.label("", size: 12, color: UIStyle.dimText, bold: true, align: .right)
    private let statusLabel = UIStyle.label("", size: 12, color: Palette.warning, bold: true, align: .right)

    init() {
        root.addChild(UIStyle.panel(size: VitalsPanel.size))
        let back = UIStyle.rect(size: CGSize(width: barWidth, height: 10), color: SKColor(white: 0.1, alpha: 1))
        back.position = CGPoint(x: 0, y: -20)
        root.addChild(back)
        fill = UIStyle.rect(size: CGSize(width: barWidth, height: 10), color: Palette.player)
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position = CGPoint(x: -barWidth / 2, y: -20)
        root.addChild(fill)
        hpLabel.position = CGPoint(x: -barWidth / 2, y: 10)
        livesLabel.position = CGPoint(x: barWidth / 2, y: 18)
        statusLabel.position = CGPoint(x: barWidth / 2, y: 2)
        for node in [hpLabel, livesLabel, statusLabel] { root.addChild(node) }
    }

    func update(soldier: Soldier) {
        let hp = Int(soldier.hp.rounded(.up))
        hpLabel.text = "✚ \(hp)"
        hpLabel.fontColor = soldier.hp > 30 ? UIStyle.textColor : Palette.warning
        fill.xScale = soldier.hpFraction
        fill.color = soldier.hp > 30 ? Palette.player : Palette.warning
        livesLabel.text = ""
        if soldier.isStunned {
            statusLabel.text = "STUNNED"
        } else if soldier.isBlind {
            statusLabel.text = "BLINDED"
        } else if soldier.spawnProtection > 0 {
            statusLabel.text = "SPAWN PROTECTED"
        } else {
            statusLabel.text = ""
        }
    }
}

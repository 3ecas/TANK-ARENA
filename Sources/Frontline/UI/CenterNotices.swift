import SpriteKit

/// Recall channel bar, respawn countdown and aiming hint above the ability bar.
@MainActor
final class CenterNotices {
    let root = SKNode()
    private let barBack = UIStyle.rect(size: CGSize(width: 220, height: 10), color: SKColor(white: 0, alpha: 0.7))
    private let barFill = UIStyle.rect(size: CGSize(width: 220, height: 10), color: Palette.commandPoints)
    private let barLabel = UIStyle.label("RECALLING", size: 12, bold: true, align: .center)
    private let respawnLabel = UIStyle.label("", size: 26, color: Palette.warning, bold: true, align: .center)
    private let hintLabel = UIStyle.label("", size: 12, color: UIStyle.accent, bold: true, align: .center)

    init() {
        barFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        barFill.position = CGPoint(x: -110, y: 0)
        barLabel.position = CGPoint(x: 0, y: 16)
        respawnLabel.position = CGPoint(x: 0, y: 160)
        hintLabel.position = CGPoint(x: 0, y: 36)
        for node in [barBack, barFill, barLabel, respawnLabel, hintLabel] as [SKNode] { root.addChild(node) }
    }

    func update(hero: Hero, aimingSlot: Int?) {
        let recalling = hero.recallTimer
        barBack.isHidden = recalling == nil
        barFill.isHidden = recalling == nil
        barLabel.isHidden = recalling == nil
        if let remaining = recalling {
            barFill.xScale = (1 - remaining / GameConfig.recallTime).clamped(0, 1)
        }
        respawnLabel.text = hero.isAlive ? "" : "RESPAWNING IN \(Int(hero.respawnTimer.rounded(.up)))"
        if let slot = aimingSlot, let id = hero.loadout.ability(inSlot: slot) {
            hintLabel.text = "\(AbilityCatalog.def(id).name): release to cast · Esc to cancel"
        } else {
            hintLabel.text = ""
        }
    }
}

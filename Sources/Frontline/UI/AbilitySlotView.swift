import Foundation
import SpriteKit

/// One slot of the ability bar: icon, key, rank pips, CP cost, cooldown sweep.
@MainActor
final class AbilitySlotView {
    static let side: CGFloat = 66
    let root = SKNode()
    private let frame: SKShapeNode
    private let icon: SKSpriteNode
    private let nameLabel = UIStyle.label("", size: 13, bold: true, align: .center)
    private let keyLabel: SKLabelNode
    private let rankLabel = UIStyle.label("", size: 10, color: UIStyle.accent, bold: true, align: .center)
    private let cpLabel = UIStyle.label("", size: 10, color: Palette.commandPoints, bold: true, align: .right)
    private let cooldownShade: SKSpriteNode
    private let cooldownLabel = UIStyle.label("", size: 18, bold: true, align: .center)
    private let upgradeLabel = UIStyle.label("+", size: 16, color: Palette.heal, bold: true, align: .center)

    init(keyName: String) {
        let side = AbilitySlotView.side
        frame = SKShapeNode(rectOf: CGSize(width: side, height: side), cornerRadius: 6)
        frame.fillColor = UIStyle.panelColor
        frame.lineWidth = 2
        icon = UIStyle.rect(size: CGSize(width: side - 10, height: side - 10), color: .gray)
        cooldownShade = UIStyle.rect(size: CGSize(width: side - 10, height: side - 10), color: SKColor(white: 0, alpha: 0.65))
        cooldownShade.anchorPoint = CGPoint(x: 0.5, y: 0)
        cooldownShade.position = CGPoint(x: 0, y: -(side - 10) / 2)
        keyLabel = UIStyle.label(keyName, size: 10, color: UIStyle.textColor, bold: true)
        keyLabel.position = CGPoint(x: -side / 2 + 5, y: side / 2 - 9)
        rankLabel.position = CGPoint(x: 0, y: -side / 2 + 9)
        cpLabel.position = CGPoint(x: side / 2 - 4, y: side / 2 - 9)
        upgradeLabel.position = CGPoint(x: side / 2 - 8, y: -side / 2 + 10)
        nameLabel.position = CGPoint(x: 0, y: 2)
        root.addChild(frame)
        for node in [icon, nameLabel, cooldownShade, cooldownLabel, keyLabel, rankLabel, cpLabel, upgradeLabel] as [SKNode] {
            root.addChild(node)
        }
    }

    func update(hero: Hero, slot: Int, aiming: Bool, cooldownMultiplier: (AbilityDef, Int) -> CGFloat) {
        guard let id = hero.loadout.ability(inSlot: slot) else {
            icon.color = SKColor(white: 0.15, alpha: 1)
            nameLabel.text = "—"
            rankLabel.text = ""
            cpLabel.text = ""
            cooldownShade.isHidden = true
            cooldownLabel.text = ""
            upgradeLabel.isHidden = true
            frame.strokeColor = UIStyle.panelBorder
            return
        }
        let def = AbilityCatalog.def(id)
        let rank = hero.loadout.rank(of: id)
        icon.color = AbilitySlotView.color(for: def.category)
        nameLabel.text = def.shortName
        rankLabel.text = String(repeating: "●", count: rank) + String(repeating: "○", count: AbilityDef.maxRank - rank)
        cpLabel.text = def.cpCost > 0 ? "\(def.cpCost)CP" : ""
        cpLabel.fontColor = hero.commandPoints >= def.cpCost ? Palette.commandPoints : Palette.warning
        let remaining = hero.loadout.cooldown(of: id)
        let total = Swift.max(cooldownMultiplier(def, rank), 0.01)
        cooldownShade.isHidden = remaining <= 0
        cooldownShade.yScale = (remaining / total).clamped(0, 1)
        cooldownLabel.text = remaining > 0 ? String(format: remaining < 3 ? "%.1f" : "%.0f", Double(remaining)) : ""
        upgradeLabel.isHidden = !(hero.abilityPoints > 0 && rank < AbilityDef.maxRank)
        frame.strokeColor = aiming ? UIStyle.accent : (def.tier == .ultimate ? Palette.commandPoints : UIStyle.panelBorder)
        frame.lineWidth = aiming ? 4 : 2
    }

    static func color(for category: AbilityCategory) -> SKColor {
        switch category {
        case .combat: return SKColor(red: 0.55, green: 0.25, blue: 0.2, alpha: 1)
        case .support: return SKColor(red: 0.2, green: 0.45, blue: 0.3, alpha: 1)
        case .callIn: return SKColor(red: 0.55, green: 0.42, blue: 0.15, alpha: 1)
        case .summon: return SKColor(red: 0.22, green: 0.32, blue: 0.55, alpha: 1)
        }
    }
}

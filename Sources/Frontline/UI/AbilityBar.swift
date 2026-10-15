import SpriteKit

/// The 4 ability slots labelled LMB / Q / E / R.
@MainActor
final class AbilityBar {
    let root = SKNode()
    private let slots: [AbilitySlotView]
    private let rollShade = UIStyle.rect(size: CGSize(width: 44, height: 44), color: SKColor(white: 0, alpha: 0.65))
    private let rollLabel = UIStyle.label("", size: 13, bold: true, align: .center)
    static let spacing: CGFloat = 10

    init() {
        slots = Loadout.slotLabels.map { AbilitySlotView(keyName: $0) }
        let step = AbilitySlotView.side + AbilityBar.spacing
        for (index, slot) in slots.enumerated() {
            slot.root.position = CGPoint(x: (CGFloat(index) - 1.5) * step, y: 0)
            root.addChild(slot.root)
        }
        // Built-in roll on F, to the right of R.
        let roll = SKNode()
        roll.position = CGPoint(x: 2.5 * step + 10, y: -11)
        let frame = UIStyle.panel(size: CGSize(width: 44, height: 44))
        let icon = UIStyle.label("ROLL", size: 10, color: UIStyle.accent, bold: true, align: .center)
        let key = UIStyle.label("F", size: 10, bold: true)
        key.position = CGPoint(x: -18, y: 14)
        rollShade.anchorPoint = CGPoint(x: 0.5, y: 0)
        rollShade.position = CGPoint(x: 0, y: -22)
        for node in [frame, icon, rollShade, rollLabel, key] as [SKNode] { roll.addChild(node) }
        root.addChild(roll)
    }

    static var width: CGFloat { 4 * AbilitySlotView.side + 3 * spacing }

    func update(hero: Hero, aimingSlot: Int?, cooldown: (AbilityDef, Int) -> CGFloat) {
        for (index, slot) in slots.enumerated() {
            slot.update(hero: hero, slot: index, aiming: aimingSlot == index, cooldownMultiplier: cooldown)
        }
        let rollRemaining = hero.dodgeCooldown
        rollShade.isHidden = rollRemaining <= 0
        rollShade.yScale = (rollRemaining / GameConfig.dodgeCooldown).clamped(0, 1)
        rollLabel.text = rollRemaining > 0 ? "\(Int(rollRemaining.rounded(.up)))" : ""
    }
}

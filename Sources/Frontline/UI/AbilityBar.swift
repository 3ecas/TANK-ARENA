import SpriteKit

/// The 4 ability slots labelled LMB / Q / E / R.
@MainActor
final class AbilityBar {
    let root = SKNode()
    private let slots: [AbilitySlotView]
    static let spacing: CGFloat = 10

    init() {
        slots = Loadout.slotLabels.map { AbilitySlotView(keyName: $0) }
        let step = AbilitySlotView.side + AbilityBar.spacing
        for (index, slot) in slots.enumerated() {
            slot.root.position = CGPoint(x: (CGFloat(index) - 1.5) * step, y: 0)
            root.addChild(slot.root)
        }
    }

    static var width: CGFloat { 4 * AbilitySlotView.side + 3 * spacing }

    func update(hero: Hero, aimingSlot: Int?, cooldown: (AbilityDef, Int) -> CGFloat) {
        for (index, slot) in slots.enumerated() {
            slot.update(hero: hero, slot: index, aiming: aimingSlot == index, cooldownMultiplier: cooldown)
        }
    }
}

import SpriteKit

/// Bottom of the shop: the 4 equipped ability slots (click to equip the selection) and the 6 gear slots.
@MainActor
enum LoadoutStrip {
    static func build(into parent: SKNode, hero: Hero, selection: ShopSelection?, onSlot: @escaping (Int) -> Void) {
        let title = UIStyle.label("LOADOUT", size: 13, color: UIStyle.accent, bold: true)
        title.position = CGPoint(x: -430, y: -168)
        parent.addChild(title)
        var selectedId: AbilityID?
        if case .ability(let id)? = selection { selectedId = id }
        for slot in 0..<Loadout.slotCount {
            let name = hero.loadout.ability(inSlot: slot).map { AbilityCatalog.def($0).shortName } ?? "—"
            let button = UIButton(title: "\(Loadout.slotLabels[slot]): \(name)", size: CGSize(width: 150, height: 36),
                                  fontSize: 12)
            button.position = CGPoint(x: -355 + CGFloat(slot) * 160, y: -195)
            button.isSelected = selectedId != nil && hero.loadout.ability(inSlot: slot) == selectedId
            button.onClick = { onSlot(slot) }
            parent.addChild(button)
        }
        let gearTitle = UIStyle.label("GEAR", size: 11, color: UIStyle.dimText, bold: true)
        gearTitle.position = CGPoint(x: -430, y: -236)
        parent.addChild(gearTitle)
        for index in 0..<HeroConfig.maxGearSlots {
            let box = UIStyle.panel(size: CGSize(width: 122, height: 26), color: SKColor(white: 0.12, alpha: 1))
            box.position = CGPoint(x: -320 + CGFloat(index) * 130, y: -236)
            let name = index < hero.gear.count ? GearCatalog.def(hero.gear[index]).name : "empty"
            let label = UIStyle.label(name, size: 10, color: index < hero.gear.count ? UIStyle.textColor : UIStyle.dimText,
                                      align: .center)
            box.addChild(label)
            parent.addChild(box)
        }
    }
}

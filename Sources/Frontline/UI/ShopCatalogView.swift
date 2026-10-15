import SpriteKit

/// Builds the item lists for each shop tab.
@MainActor
enum ShopCatalogView {
    static func abilities(into parent: SKNode, hero: Hero, selection: ShopSelection?,
                          onSelect: @escaping (ShopSelection) -> Void) {
        for (column, category) in AbilityCategory.allCases.enumerated() {
            let x = -380 + CGFloat(column) * 130
            let header = UIStyle.label(category.displayName.uppercased(), size: 12,
                                       color: AbilitySlotView.color(for: category).withAlphaComponent(1), bold: true,
                                       align: .center)
            header.fontColor = UIStyle.accent
            header.position = CGPoint(x: x, y: 165)
            parent.addChild(header)
            for (row, def) in AbilityCatalog.abilities(in: category).enumerated() {
                let rank = hero.loadout.rank(of: def.id)
                let suffix = def.tier == .ultimate ? " ★" : ""
                let button = UIButton(title: def.name + suffix, size: CGSize(width: 124, height: 36), fontSize: 10,
                                      color: rank > 0 ? UIStyle.buttonOwned : UIStyle.buttonColor)
                button.position = CGPoint(x: x, y: 130 - CGFloat(row) * 44)
                button.isSelected = selection == .ability(def.id)
                button.onClick = { onSelect(.ability(def.id)) }
                parent.addChild(button)
                if rank > 0 {
                    let pips = UIStyle.label(String(repeating: "●", count: rank), size: 8, color: UIStyle.accent,
                                             align: .center)
                    pips.position = CGPoint(x: x, y: 130 - CGFloat(row) * 44 - 12)
                    parent.addChild(pips)
                }
            }
        }
    }

    static func weapons(into parent: SKNode, hero: Hero, selection: ShopSelection?,
                        onSelect: @escaping (ShopSelection) -> Void) {
        for (row, def) in WeaponCatalog.all.enumerated() {
            let status: String
            if hero.weaponId == def.id {
                status = "EQUIPPED"
            } else if hero.ownedWeapons.contains(def.id) {
                status = "OWNED"
            } else {
                status = "\(def.cost)g"
            }
            let owned = hero.ownedWeapons.contains(def.id)
            let button = UIButton(title: "\(def.name)  ·  \(status)", size: CGSize(width: 440, height: 50),
                                  fontSize: 14, color: owned ? UIStyle.buttonOwned : UIStyle.buttonColor)
            button.position = CGPoint(x: -175, y: 130 - CGFloat(row) * 64)
            button.isSelected = selection == .weapon(def.id)
            button.onClick = { onSelect(.weapon(def.id)) }
            parent.addChild(button)
        }
    }

    static func gear(into parent: SKNode, hero: Hero, selection: ShopSelection?,
                     onSelect: @escaping (ShopSelection) -> Void) {
        let basics = GearCatalog.all.filter { $0.requires == nil }
        for (row, basic) in basics.enumerated() {
            let y = 140 - CGFloat(row) * 50
            parent.addChild(gearButton(basic, hero: hero, selection: selection, x: -300, y: y, onSelect: onSelect))
            let arrow = UIStyle.label("→", size: 18, color: UIStyle.dimText, bold: true, align: .center)
            arrow.position = CGPoint(x: -172, y: y)
            parent.addChild(arrow)
            if let advanced = GearCatalog.all.first(where: { $0.requires == basic.id }) {
                parent.addChild(gearButton(advanced, hero: hero, selection: selection, x: -45, y: y, onSelect: onSelect))
            }
        }
    }

    private static func gearButton(_ def: GearDef, hero: Hero, selection: ShopSelection?, x: CGFloat, y: CGFloat,
                                   onSelect: @escaping (ShopSelection) -> Void) -> UIButton {
        let owned = hero.gear.contains(def.id)
        let button = UIButton(title: "\(def.name) · \(owned ? "OWNED" : "\(def.cost)g")",
                              size: CGSize(width: 226, height: 40), fontSize: 11,
                              color: owned ? UIStyle.buttonOwned : UIStyle.buttonColor)
        button.position = CGPoint(x: x, y: y)
        button.isSelected = selection == .gear(def.id)
        button.onClick = { onSelect(.gear(def.id)) }
        return button
    }
}

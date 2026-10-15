import Foundation
import SpriteKit

/// Right-hand pane of the shop: description, stats and buy / equip buttons for the selection.
@MainActor
enum ShopDetailView {
    private static let centerX: CGFloat = 275

    static func build(into parent: SKNode, selection: ShopSelection?, hero: Hero, atBase: Bool,
                      onBuy: @escaping () -> Void, onEquip: @escaping (AbilityID, Int) -> Void) {
        let backdrop = UIStyle.panel(size: CGSize(width: 330, height: 340),
                                     color: SKColor(white: 0.1, alpha: 0.9), border: UIStyle.panelBorder)
        backdrop.position = CGPoint(x: centerX, y: 15)
        parent.addChild(backdrop)
        guard let selection = selection else {
            addLines(["Select an ability, weapon", "or gear item."], to: parent, startY: 120, color: UIStyle.dimText)
            return
        }
        let info = describe(selection, hero: hero)
        let title = UIStyle.label(info.title, size: 17, color: UIStyle.accent, bold: true, align: .center)
        title.position = CGPoint(x: centerX, y: 160)
        parent.addChild(title)
        var lines = UIStyle.wrap(info.summary, width: 34)
        lines.append("")
        lines += info.stats
        addLines(lines, to: parent, startY: 130, color: UIStyle.textColor)

        let buy = UIButton(title: info.action, size: CGSize(width: 230, height: 38), fontSize: 13)
        buy.position = CGPoint(x: centerX, y: -78)
        buy.isEnabled = atBase && info.canAct
        buy.onClick = onBuy
        parent.addChild(buy)
        if !atBase {
            let warning = UIStyle.label("Return to base to buy or equip", size: 11, color: Palette.warning,
                                        bold: true, align: .center)
            warning.position = CGPoint(x: centerX, y: -104)
            parent.addChild(warning)
        }
        if case .ability(let id) = selection, hero.loadout.owns(id) {
            let label = UIStyle.label("Equip to slot:", size: 11, color: UIStyle.dimText, align: .center)
            label.position = CGPoint(x: centerX, y: -118)
            parent.addChild(label)
            for slot in 0..<Loadout.slotCount {
                let button = UIButton(title: Loadout.slotLabels[slot], size: CGSize(width: 64, height: 30), fontSize: 12)
                button.position = CGPoint(x: centerX + (CGFloat(slot) - 1.5) * 74, y: -142)
                button.isSelected = hero.loadout.slot(of: id) == slot
                button.isEnabled = atBase
                button.onClick = { onEquip(id, slot) }
                parent.addChild(button)
            }
        }
    }

    private struct Info {
        var title: String
        var summary: String
        var stats: [String]
        var action: String
        var canAct: Bool
    }

    private static func describe(_ selection: ShopSelection, hero: Hero) -> Info {
        switch selection {
        case .ability(let id):
            let def = AbilityCatalog.def(id)
            let rank = hero.loadout.rank(of: id)
            let cooldowns = def.cooldowns.map { String(format: "%.0f", Double($0)) }.joined(separator: "/")
            var stats = ["\(def.category.displayName)\(def.tier == .ultimate ? " · ULTIMATE" : "")",
                         "Rank \(rank)/\(AbilityDef.maxRank)", "Cooldown \(cooldowns)s"]
            if def.cpCost > 0 { stats.append("Costs \(def.cpCost) Command Points") }
            if def.range > 0 { stats.append("Range \(Int(def.range))") }
            if def.isCallIn { stats.append("Call-in (Airfield bonus)") }
            let price = AbilityShop.price(of: id, for: hero)
            let action = price.map { rank == 0 ? "Buy · \($0)g" : "Upgrade · \($0)g" } ?? "Max rank"
            return Info(title: def.name, summary: def.summary, stats: stats, action: action,
                        canAct: price.map { hero.gold >= $0 } ?? false)
        case .weapon(let id):
            let def = WeaponCatalog.def(id)
            let rate = 1 / Double(def.interval)
            let stats = [String(format: "Damage %.0f x%d", Double(def.damage), def.pellets),
                         "Range \(Int(def.range))", String(format: "Fire rate %.1f/s", rate),
                         "Magazine \(def.magSize) · Reload \(String(format: "%.1f", Double(def.reloadTime)))s",
                         String(format: "Move speed x%.2f", Double(def.speedMultiplier))]
            let owned = hero.ownedWeapons.contains(id)
            let equipped = hero.weaponId == id
            let action = equipped ? "Equipped" : (owned ? "Equip" : "Buy · \(def.cost)g")
            return Info(title: def.name, summary: def.summary, stats: stats, action: action,
                        canAct: !equipped && (owned || hero.gold >= def.cost))
        case .gear(let id):
            let def = GearCatalog.def(id)
            var stats = ["Gear slots used: \(hero.gear.count)/\(HeroConfig.maxGearSlots)"]
            if let required = def.requires { stats.append("Upgrades: \(GearCatalog.def(required).name)") }
            let owned = hero.gear.contains(id)
            return Info(title: def.name, summary: def.summary, stats: stats,
                        action: owned ? "Owned" : "Buy · \(def.cost)g",
                        canAct: !owned && GearShop.canBuy(id, hero: hero) && hero.gold >= def.cost)
        }
    }

    private static func addLines(_ lines: [String], to parent: SKNode, startY: CGFloat, color: SKColor) {
        for (index, line) in lines.enumerated() {
            let label = UIStyle.label(line, size: 12, color: color, align: .center)
            label.position = CGPoint(x: centerX, y: startY - CGFloat(index) * 18)
            parent.addChild(label)
        }
    }
}

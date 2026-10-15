import SpriteKit

enum ShopTab: CaseIterable {
    case abilities, weapons, gear

    var title: String {
        switch self {
        case .abilities: return "Abilities"
        case .weapons: return "Weapons"
        case .gear: return "Gear"
        }
    }
}

enum ShopSelection: Equatable {
    case ability(AbilityID)
    case weapon(WeaponID)
    case gear(GearID)
}

/// The armory: tabs (Abilities / Weapons / Gear), a detail pane and the loadout strip.
/// Purchases go through `ShopService`; this class only displays state and forwards clicks.
@MainActor
final class ShopPanel {
    static let size = CGSize(width: 900, height: 560)
    let root = SKNode()
    private unowned let session: GameSession
    private let content = SKNode()
    private let goldLabel = UIStyle.label("", size: 16, color: Palette.gold, bold: true, align: .right)
    private let messageLabel = UIStyle.label("", size: 13, color: UIStyle.accent, bold: true, align: .center)
    private var tabButtons: [UIButton] = []
    private var tab: ShopTab = .abilities
    private var selection: ShopSelection?
    private var refreshTimer: CGFloat = 0
    /// Called after every purchase / equip attempt (for sounds).
    var onResult: ((ShopResult) -> Void)?

    var isOpen: Bool { !root.isHidden }

    init(session: GameSession) {
        self.session = session
        root.isHidden = true
        buildFrame()
    }

    func open() {
        root.isHidden = false
        messageLabel.text = "Click an item to see details. Equip abilities in the loadout strip."
        rebuild()
    }

    func close() {
        root.isHidden = true
    }

    func update(dt: CGFloat) {
        guard isOpen else { return }
        goldLabel.text = "GOLD \(session.player.gold)"
        refreshTimer -= dt
        if refreshTimer <= 0 { rebuild() }
    }

    /// Point (in the shop's parent coordinates) inside the panel background?
    func contains(_ point: CGPoint) -> Bool {
        let local = point - root.position
        return abs(local.x) <= ShopPanel.size.width / 2 && abs(local.y) <= ShopPanel.size.height / 2
    }

    // MARK: Building

    private func buildFrame() {
        let size = ShopPanel.size
        root.addChild(UIStyle.panel(size: size, color: SKColor(red: 0.06, green: 0.08, blue: 0.07, alpha: 0.96)))
        let title = UIStyle.label("ARMORY", size: 24, color: UIStyle.accent, bold: true)
        title.position = CGPoint(x: -size.width / 2 + 20, y: size.height / 2 - 30)
        root.addChild(title)
        goldLabel.position = CGPoint(x: size.width / 2 - 60, y: size.height / 2 - 30)
        root.addChild(goldLabel)
        let close = UIButton(title: "X", size: CGSize(width: 32, height: 28))
        close.position = CGPoint(x: size.width / 2 - 26, y: size.height / 2 - 28)
        close.onClick = { [unowned self] in self.close() }
        root.addChild(close)
        for (index, tab) in ShopTab.allCases.enumerated() {
            let button = UIButton(title: tab.title, size: CGSize(width: 140, height: 32))
            button.position = CGPoint(x: -330 + CGFloat(index) * 150, y: 205)
            button.onClick = { [unowned self] in
                self.tab = tab
                self.selection = nil
                self.rebuild()
            }
            root.addChild(button)
            tabButtons.append(button)
        }
        messageLabel.position = CGPoint(x: 0, y: -size.height / 2 + 16)
        root.addChild(messageLabel)
        root.addChild(content)
    }

    private func rebuild() {
        refreshTimer = 0.5
        content.removeAllChildren()
        let hero = session.player
        let atBase = session.ctx.shop.isAtShop(hero)
        for (index, button) in tabButtons.enumerated() {
            button.isSelected = ShopTab.allCases[index] == tab
        }
        let select: (ShopSelection) -> Void = { [unowned self] selection in
            self.selection = selection
            self.rebuild()
        }
        switch tab {
        case .abilities: ShopCatalogView.abilities(into: content, hero: hero, selection: selection, onSelect: select)
        case .weapons: ShopCatalogView.weapons(into: content, hero: hero, selection: selection, onSelect: select)
        case .gear: ShopCatalogView.gear(into: content, hero: hero, selection: selection, onSelect: select)
        }
        ShopDetailView.build(into: content, selection: selection, hero: hero, atBase: atBase,
                             onBuy: { [unowned self] in self.buySelection() },
                             onEquip: { [unowned self] id, slot in self.equip(id, slot: slot) })
        LoadoutStrip.build(into: content, hero: hero, selection: selection,
                           onSlot: { [unowned self] slot in self.slotClicked(slot) })
    }

    // MARK: Actions

    private func buySelection() {
        guard let selection = selection else { return }
        let shop = session.ctx.shop!
        let hero = session.player
        let result: ShopResult
        switch selection {
        case .ability(let id): result = shop.buyAbility(id, for: hero)
        case .weapon(let id): result = shop.buyWeapon(id, for: hero)
        case .gear(let id): result = shop.buyGear(id, for: hero)
        }
        report(result)
    }

    private func equip(_ id: AbilityID, slot: Int) {
        report(session.ctx.shop.equip(id, slot: slot, for: session.player))
    }

    private func slotClicked(_ slot: Int) {
        if case .ability(let id)? = selection, session.player.loadout.owns(id) {
            equip(id, slot: slot)
        } else if let id = session.player.loadout.ability(inSlot: slot) {
            selection = .ability(id)
            tab = .abilities
            rebuild()
        }
    }

    private func report(_ result: ShopResult) {
        messageLabel.text = result.message
        messageLabel.fontColor = result.isSuccess ? Palette.heal : Palette.warning
        onResult?(result)
        rebuild()
    }
}

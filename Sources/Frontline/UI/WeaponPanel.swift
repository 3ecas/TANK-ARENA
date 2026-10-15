import SpriteKit

/// Bottom-right: weapon slots (1 primary, 2 pistol), ammo, grenade and knife hints.
@MainActor
final class WeaponPanel {
    static let size = CGSize(width: 290, height: 96)
    let root = SKNode()
    private let ammoLabel = UIStyle.label("", size: 28, bold: true, align: .right)
    private let nameLabel = UIStyle.label("", size: 13, color: UIStyle.accent, bold: true, align: .right)
    private let slotLabels = [UIStyle.label("", size: 12, bold: true), UIStyle.label("", size: 12, bold: true)]
    private let grenadeLabel = UIStyle.label("", size: 12, bold: true)
    private let knifeLabel = UIStyle.label("", size: 12, bold: true)

    init() {
        root.addChild(UIStyle.panel(size: WeaponPanel.size))
        let right = WeaponPanel.size.width / 2 - 12
        let left = -WeaponPanel.size.width / 2 + 12
        ammoLabel.position = CGPoint(x: right, y: 18)
        nameLabel.position = CGPoint(x: right, y: -10)
        slotLabels[0].position = CGPoint(x: left, y: 30)
        slotLabels[1].position = CGPoint(x: left, y: 12)
        grenadeLabel.position = CGPoint(x: left, y: -10)
        knifeLabel.position = CGPoint(x: left, y: -30)
        for node in [ammoLabel, nameLabel, grenadeLabel, knifeLabel] + slotLabels { root.addChild(node) }
    }

    func update(soldier: Soldier) {
        let weapon = soldier.activeWeapon
        if weapon.isReloading {
            ammoLabel.text = "RELOADING"
            ammoLabel.fontSize = 20
        } else {
            let reserve = weapon.reserve.map { "\($0)" } ?? "∞"
            ammoLabel.text = "\(weapon.magazine) / \(reserve)"
            ammoLabel.fontSize = 28
        }
        ammoLabel.fontColor = weapon.magazine == 0 ? Palette.warning : UIStyle.textColor
        nameLabel.text = weapon.def.name.uppercased()
        for (index, label) in slotLabels.enumerated() {
            let active = index == soldier.activeIndex
            label.text = "\(index + 1)  \(soldier.weapons[index].def.name)"
            label.fontColor = active ? UIStyle.accent : UIStyle.dimText
        }
        if let grenade = soldier.grenade {
            grenadeLabel.text = "G  \(grenade.displayName)"
            grenadeLabel.fontColor = UIStyle.textColor
        } else {
            grenadeLabel.text = "G  no grenade"
            grenadeLabel.fontColor = UIStyle.dimText
        }
        knifeLabel.text = soldier.knifeCooldown > 0 ? "F  Knife (…)" : "F  Knife"
        knifeLabel.fontColor = soldier.knifeCooldown > 0 ? UIStyle.dimText : UIStyle.textColor
    }
}

import SpriteKit

/// Bottom-left panel: HP, ammo, level/XP, gold, command points, ability points.
@MainActor
final class StatusPanel {
    let root = SKNode()
    static let size = CGSize(width: 300, height: 124)
    private let hpFill: SKSpriteNode
    private let xpFill: SKSpriteNode
    private let hpLabel = UIStyle.label("", size: 13, bold: true, align: .center)
    private let ammoLabel = UIStyle.label("", size: 13, bold: true)
    private let levelLabel = UIStyle.label("", size: 12, color: UIStyle.accent, bold: true)
    private let goldLabel = UIStyle.label("", size: 13, color: Palette.gold, bold: true, align: .right)
    private let cpLabel = UIStyle.label("", size: 12, color: Palette.commandPoints, bold: true)
    private let pointsLabel = UIStyle.label("", size: 11, color: Palette.heal, bold: true, align: .right)
    private let barWidth: CGFloat = 276

    init() {
        let size = StatusPanel.size
        root.addChild(UIStyle.panel(size: size))
        let hpBack = UIStyle.rect(size: CGSize(width: barWidth, height: 18), color: SKColor(white: 0.1, alpha: 1))
        hpBack.position = CGPoint(x: 0, y: 34)
        root.addChild(hpBack)
        hpFill = UIStyle.rect(size: CGSize(width: barWidth, height: 18), color: Palette.player)
        hpFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        hpFill.position = CGPoint(x: -barWidth / 2, y: 34)
        root.addChild(hpFill)
        hpLabel.position = CGPoint(x: 0, y: 34)
        root.addChild(hpLabel)

        let xpBack = UIStyle.rect(size: CGSize(width: barWidth, height: 5), color: SKColor(white: 0.12, alpha: 1))
        xpBack.position = CGPoint(x: 0, y: 19)
        root.addChild(xpBack)
        xpFill = UIStyle.rect(size: CGSize(width: barWidth, height: 5), color: UIStyle.accent)
        xpFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        xpFill.position = CGPoint(x: -barWidth / 2, y: 19)
        root.addChild(xpFill)

        let left = -barWidth / 2
        levelLabel.position = CGPoint(x: left, y: 52)
        goldLabel.position = CGPoint(x: -left, y: 52)
        ammoLabel.position = CGPoint(x: left, y: 0)
        cpLabel.position = CGPoint(x: left, y: -22)
        pointsLabel.position = CGPoint(x: -left, y: -22)
        for label in [levelLabel, goldLabel, ammoLabel, cpLabel, pointsLabel] { root.addChild(label) }
        let hint = UIStyle.label("F roll · B recall · P shop · Tab score", size: 10, color: UIStyle.dimText)
        hint.position = CGPoint(x: left, y: -46)
        root.addChild(hint)
    }

    func update(hero: Hero) {
        hpFill.xScale = hero.hpFraction
        hpFill.color = hero.hpFraction > 0.35 ? Palette.player : Palette.damageTaken
        hpLabel.text = "\(Int(hero.hp.rounded(.up))) / \(Int(hero.maxHp))"
        xpFill.xScale = hero.level >= HeroConfig.maxLevel ? 1 : (hero.xp / hero.xpToNextLevel).clamped(0, 1)
        levelLabel.text = "LEVEL \(hero.level)  \(hero.weapon.name.uppercased())"
        goldLabel.text = "\(hero.gold) g"
        if hero.isReloading {
            ammoLabel.text = "AMMO  RELOADING..."
            ammoLabel.fontColor = Palette.warning
        } else {
            ammoLabel.text = "AMMO  \(hero.ammo) / \(hero.stats.magSize)"
            ammoLabel.fontColor = UIStyle.textColor
        }
        let pips = String(repeating: "◆", count: hero.commandPoints)
            + String(repeating: "◇", count: Swift.max(0, EconomyConfig.maxCommandPoints - hero.commandPoints))
        cpLabel.text = "CP \(pips)"
        pointsLabel.text = hero.abilityPoints > 0 ? "+\(hero.abilityPoints) pts (1-4)" : ""
    }
}

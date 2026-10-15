import SpriteKit

/// Top-centre Breakthrough panel: your role, the sector under attack, attacker tickets,
/// the two active zones (tinted by owner) and soldiers alive per team.
@MainActor
final class TeamCounter {
    let root = SKNode()
    private let roleLabel = UIStyle.label("", size: 11, color: UIStyle.dimText, align: .center)
    private let sectorLabel = UIStyle.label("", size: 18, color: UIStyle.accent, bold: true, align: .center)
    private let ticketLabel = UIStyle.label("", size: 12, align: .center)
    private let blueAlive = UIStyle.label("", size: 13, color: Palette.team(.blue), bold: true, align: .right)
    private let redAlive = UIStyle.label("", size: 13, color: Palette.team(.red), bold: true)
    private let zoneLabels = [UIStyle.label("", size: 15, bold: true, align: .center),
                              UIStyle.label("", size: 15, bold: true, align: .center)]
    private var pulse: CGFloat = 0

    init() {
        root.addChild(UIStyle.panel(size: CGSize(width: 360, height: 84)))
        roleLabel.position = CGPoint(x: 0, y: 26)
        sectorLabel.position = CGPoint(x: 0, y: 6)
        ticketLabel.position = CGPoint(x: 0, y: -14)
        blueAlive.position = CGPoint(x: -150, y: 4)
        redAlive.position = CGPoint(x: 150, y: 4)
        blueAlive.horizontalAlignmentMode = .left
        redAlive.horizontalAlignmentMode = .right
        zoneLabels[0].position = CGPoint(x: -30, y: -34)
        zoneLabels[1].position = CGPoint(x: 30, y: -34)
        for node in [roleLabel, sectorLabel, ticketLabel, blueAlive, redAlive] + zoneLabels { root.addChild(node) }
    }

    func update(world: BattleWorld, playerTeam: Team) {
        pulse += 1 / 60
        let attacking = world.attackers == playerTeam
        roleLabel.text = attacking ? "ATTACKING — TAKE BOTH ZONES" : "DEFENDING — HOLD THE ZONES"
        sectorLabel.text = "SECTOR \(world.currentSector.name)  (\(world.sector + 1)/\(world.map.sectors.count))"
        ticketLabel.text = "Attacker tickets: \(world.tickets)"
        ticketLabel.fontColor = world.tickets < 30 ? Palette.warning : UIStyle.textColor
        blueAlive.text = "BLUE \(world.aliveCount(.blue))"
        redAlive.text = "\(world.aliveCount(.red)) RED"
        let active = world.activeZones
        for (index, label) in zoneLabels.enumerated() {
            guard index < active.count else {
                label.text = ""
                continue
            }
            let zone = active[index]
            label.text = zone.name
            label.fontColor = zone.owner.map { Palette.team($0) } ?? UIStyle.dimText
            label.alpha = zone.isContested || zone.capturingTeam != nil ? 0.45 + 0.55 * abs(sin(pulse * 6)) : 1
        }
    }
}

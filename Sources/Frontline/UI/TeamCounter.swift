import SpriteKit

/// Top-centre scoreboard: zone points, match countdown (or SUDDEN DEATH), alive counts and zone ownership.
@MainActor
final class TeamCounter {
    let root = SKNode()
    private let blueScore = UIStyle.label("", size: 26, color: Palette.team(.blue), bold: true, align: .right)
    private let redScore = UIStyle.label("", size: 26, color: Palette.team(.red), bold: true)
    private let blueAlive = UIStyle.label("", size: 11, color: UIStyle.dimText, align: .right)
    private let redAlive = UIStyle.label("", size: 11, color: UIStyle.dimText)
    private let timerLabel = UIStyle.label("", size: 16, color: UIStyle.accent, bold: true, align: .center)
    private var zoneLabels: [SKLabelNode] = []

    init() {
        root.addChild(UIStyle.panel(size: CGSize(width: 340, height: 74)))
        blueScore.position = CGPoint(x: -62, y: 10)
        redScore.position = CGPoint(x: 62, y: 10)
        blueAlive.position = CGPoint(x: -62, y: -12)
        redAlive.position = CGPoint(x: 62, y: -12)
        timerLabel.position = CGPoint(x: 0, y: 12)
        for node in [blueScore, redScore, blueAlive, redAlive, timerLabel] { root.addChild(node) }
        for (index, spec) in ZoneConfig.zones.enumerated() {
            let label = UIStyle.label(spec.name, size: 14, bold: true, align: .center)
            label.position = CGPoint(x: CGFloat(index - 1) * 26, y: -28)
            root.addChild(label)
            zoneLabels.append(label)
        }
    }

    func update(world: BattleWorld) {
        blueScore.text = "\(world.score(.blue))"
        redScore.text = "\(world.score(.red))"
        blueAlive.text = "\(world.aliveCount(.blue)) alive +\(pending(world, .blue))"
        redAlive.text = "+\(pending(world, .red)) \(world.aliveCount(.red)) alive"
        if world.suddenDeath {
            timerLabel.text = "SUDDEN DEATH"
            timerLabel.fontColor = Palette.warning
            timerLabel.fontSize = 13
        } else {
            timerLabel.text = UIStyle.formatTime(world.timeRemaining.rounded(.up))
            timerLabel.fontColor = world.timeRemaining < 30 ? Palette.warning : UIStyle.accent
            timerLabel.fontSize = 16
        }
        for (label, zone) in zip(zoneLabels, world.zones) {
            label.fontColor = zone.owner.map { Palette.team($0) } ?? UIStyle.dimText
            label.alpha = zone.isContested ? 0.5 : 1
        }
    }

    private func pending(_ world: BattleWorld, _ team: Team) -> Int {
        world.soldiers(of: team).filter { $0.isAwaitingRespawn }.count
    }
}

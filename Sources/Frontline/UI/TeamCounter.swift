import SpriteKit

/// Top-centre: soldiers alive per team (+ how many can still respawn) and the battle timer.
@MainActor
final class TeamCounter {
    let root = SKNode()
    private let blueLabel = UIStyle.label("", size: 22, color: Palette.team(.blue), bold: true, align: .right)
    private let redLabel = UIStyle.label("", size: 22, color: Palette.team(.red), bold: true)
    private let blueReserve = UIStyle.label("", size: 11, color: UIStyle.dimText, align: .right)
    private let redReserve = UIStyle.label("", size: 11, color: UIStyle.dimText)
    private let timerLabel = UIStyle.label("", size: 13, color: UIStyle.accent, bold: true, align: .center)

    init() {
        root.addChild(UIStyle.panel(size: CGSize(width: 260, height: 58)))
        blueLabel.position = CGPoint(x: -24, y: 8)
        redLabel.position = CGPoint(x: 24, y: 8)
        blueReserve.position = CGPoint(x: -24, y: -15)
        redReserve.position = CGPoint(x: 24, y: -15)
        timerLabel.position = CGPoint(x: 0, y: 8)
        for node in [blueLabel, redLabel, blueReserve, redReserve, timerLabel] { root.addChild(node) }
    }

    func update(world: BattleWorld) {
        blueLabel.text = "BLUE \(world.aliveCount(.blue))"
        redLabel.text = "\(world.aliveCount(.red)) RED"
        blueReserve.text = "+\(pending(world, .blue)) respawning"
        redReserve.text = "+\(pending(world, .red)) respawning"
        timerLabel.text = UIStyle.formatTime(world.time)
    }

    private func pending(_ world: BattleWorld, _ team: Team) -> Int {
        world.soldiers(of: team).filter { $0.isAwaitingRespawn }.count
    }
}

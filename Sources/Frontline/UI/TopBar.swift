import SpriteKit

/// Top of the screen: team kill score, game timer and the player's KDA.
@MainActor
final class TopBar {
    let root = SKNode()
    private let scoreLabel = UIStyle.label("", size: 16, bold: true, align: .center)
    private let timerLabel = UIStyle.label("", size: 14, color: UIStyle.accent, bold: true, align: .center)
    private let kdaLabel = UIStyle.label("", size: 13, bold: true)
    private let kdaPanel = UIStyle.panel(size: CGSize(width: 250, height: 30))

    init() {
        let center = UIStyle.panel(size: CGSize(width: 240, height: 52))
        root.addChild(center)
        scoreLabel.position = CGPoint(x: 0, y: 9)
        timerLabel.position = CGPoint(x: 0, y: -12)
        root.addChild(scoreLabel)
        root.addChild(timerLabel)
        root.addChild(kdaPanel)
        kdaPanel.addChild(kdaLabel)
        kdaLabel.position = CGPoint(x: -115, y: 0)
    }

    /// Positions the KDA box at the top-left corner relative to the centred bar.
    func layout(screen: CGSize) {
        kdaPanel.position = CGPoint(x: -screen.width / 2 + 140, y: 8)
    }

    func update(session: GameSession) {
        let blue = session.score.teamKills(.blue)
        let red = session.score.teamKills(.red)
        scoreLabel.text = "BLUE \(blue)  ⚔  \(red) RED"
        timerLabel.text = UIStyle.formatTime(session.world.time)
        let p = session.player
        kdaLabel.text = "K/D/A \(p.kills)/\(p.deaths)/\(p.assists)  CS \(p.troopKills)"
    }
}

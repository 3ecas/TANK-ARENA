import SpriteKit

/// Tab scoreboard: every soldier of both teams with kills, deaths and status.
@MainActor
final class Scoreboard {
    let root = SKNode()
    private unowned let session: GameSession
    private var rows: [(Soldier, SKLabelNode)] = []

    init(session: GameSession) {
        self.session = session
        root.isHidden = true
        root.addChild(UIStyle.panel(size: CGSize(width: 820, height: 600)))
        for (column, team) in Team.playable.enumerated() {
            let x: CGFloat = column == 0 ? -395 : 15
            let title = UIStyle.label(team == .blue ? "BLUE TEAM" : "RED TEAM", size: 15, color: Palette.team(team),
                                      bold: true)
            title.position = CGPoint(x: x, y: 275)
            root.addChild(title)
            let header = UIStyle.label(Scoreboard.format("NAME", "K", "D", "STATUS"), size: 11, color: UIStyle.dimText,
                                       bold: true)
            header.position = CGPoint(x: x, y: 252)
            root.addChild(header)
            for (index, soldier) in session.world.soldiers(of: team).enumerated() {
                let label = UIStyle.label("", size: 12, color: soldier.isPlayer ? Palette.player : UIStyle.textColor)
                label.position = CGPoint(x: x, y: 230 - CGFloat(index) * 20)
                root.addChild(label)
                rows.append((soldier, label))
            }
        }
    }

    func update() {
        guard !root.isHidden else { return }
        for (soldier, label) in rows {
            let status: String
            if soldier.isAlive {
                status = "alive"
            } else if soldier.isAwaitingRespawn {
                status = soldier.respawnTimer > 0 ? "respawn \(Int(soldier.respawnTimer.rounded(.up)))s" : "no tickets"
            } else {
                status = "out"
            }
            label.text = Scoreboard.format(soldier.name, "\(soldier.kills)", "\(soldier.deaths)", status)
            label.alpha = soldier.isEliminated ? 0.45 : 1
        }
    }

    private static func format(_ name: String, _ kills: String, _ deaths: String, _ status: String) -> String {
        pad(name, 13) + pad(kills, 5) + pad(deaths, 5) + status
    }

    private static func pad(_ text: String, _ width: Int) -> String {
        text.count >= width ? text + " " : text + String(repeating: " ", count: width - text.count)
    }
}

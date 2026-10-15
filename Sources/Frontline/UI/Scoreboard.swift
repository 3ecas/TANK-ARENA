import SpriteKit

/// Tab scoreboard: both teams' heroes with level, K/D/A, troop kills and status.
@MainActor
final class Scoreboard {
    let root = SKNode()
    private unowned let session: GameSession
    private var rows: [(Hero, SKLabelNode)] = []
    private let header = UIStyle.label("", size: 14, color: UIStyle.accent, bold: true, align: .center)

    init(session: GameSession) {
        self.session = session
        root.isHidden = true
        root.addChild(UIStyle.panel(size: CGSize(width: 700, height: 440)))
        header.position = CGPoint(x: 0, y: 195)
        root.addChild(header)
        let columns = UIStyle.label(Scoreboard.format("NAME", "LVL", "K/D/A", "CS", "WEAPON"), size: 12,
                                    color: UIStyle.dimText, bold: true)
        columns.position = CGPoint(x: -320, y: 165)
        root.addChild(columns)
        var y: CGFloat = 135
        for team in Team.playable {
            let title = UIStyle.label(team == .blue ? "BLUE TEAM" : "RED TEAM", size: 13,
                                      color: Palette.team(team), bold: true)
            title.position = CGPoint(x: -320, y: y)
            root.addChild(title)
            y -= 24
            for hero in session.world.heroes(of: team) {
                let label = UIStyle.label("", size: 13, color: hero.isPlayer ? Palette.player : UIStyle.textColor)
                label.position = CGPoint(x: -320, y: y)
                root.addChild(label)
                rows.append((hero, label))
                y -= 22
            }
            y -= 14
        }
    }

    func update() {
        guard !root.isHidden else { return }
        header.text = "SCOREBOARD  ·  \(UIStyle.formatTime(session.world.time))  ·  \(session.settings.difficulty.displayName.uppercased())"
        for (hero, label) in rows {
            let kda = "\(hero.kills)/\(hero.deaths)/\(hero.assists)"
            var status = hero.weapon.name
            if !hero.isAlive { status = "dead (\(Int(hero.respawnTimer.rounded(.up)))s)" }
            label.text = Scoreboard.format(hero.name, "\(hero.level)", kda, "\(hero.troopKills)", status)
        }
    }

    private static func format(_ name: String, _ level: String, _ kda: String, _ cs: String, _ status: String) -> String {
        pad(name, 12) + pad(level, 6) + pad(kda, 12) + pad(cs, 7) + status
    }

    private static func pad(_ text: String, _ width: Int) -> String {
        text.count >= width ? text + " " : text + String(repeating: " ", count: width - text.count)
    }
}

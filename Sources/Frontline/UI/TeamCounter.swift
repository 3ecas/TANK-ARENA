import SpriteKit

/// Top-centre round panel: your role, the round timer / bomb fuse (bomb mode) or tickets (rush),
/// bomb or station status, and how many soldiers are alive on each side.
@MainActor
final class TeamCounter {
    let root = SKNode()
    private let roleLabel = UIStyle.label("", size: 11, color: UIStyle.dimText, align: .center)
    private let timerLabel = UIStyle.label("", size: 22, color: UIStyle.accent, bold: true, align: .center)
    private let bombLabel = UIStyle.label("", size: 12, align: .center)
    private let blueAlive = UIStyle.label("", size: 15, color: Palette.team(.blue), bold: true)
    private let redAlive = UIStyle.label("", size: 15, color: Palette.team(.red), bold: true)

    init() {
        root.addChild(UIStyle.panel(size: CGSize(width: 360, height: 84)))
        roleLabel.position = CGPoint(x: 0, y: 24)
        timerLabel.position = CGPoint(x: 0, y: -2)
        bombLabel.position = CGPoint(x: 0, y: -30)
        blueAlive.position = CGPoint(x: -160, y: 0)
        redAlive.position = CGPoint(x: 160, y: 0)
        blueAlive.horizontalAlignmentMode = .left
        redAlive.horizontalAlignmentMode = .right
        for node in [roleLabel, timerLabel, bombLabel, blueAlive, redAlive] { root.addChild(node) }
    }

    func update(world: BattleWorld, playerTeam: Team) {
        let attacking = world.attackers == playerTeam
        blueAlive.text = "BLUE \(world.aliveCount(.blue))"
        redAlive.text = "\(world.aliveCount(.red)) RED"
        switch world.mode {
        case .bomb: updateBomb(world: world, attacking: attacking)
        case .rush: updateRush(world: world, attacking: attacking)
        }
    }

    private func updateBomb(world: BattleWorld, attacking: Bool) {
        roleLabel.text = attacking ? "ATTACK — PLANT THE BOMB ON A OR B" : "DEFEND — PROTECT SITES A AND B"
        let bomb = world.bomb
        if bomb.isPlanted {
            timerLabel.text = "BOMB " + UIStyle.formatTime(bomb.fuseLeft.rounded(.up))
            timerLabel.fontColor = Palette.warning
        } else {
            timerLabel.text = UIStyle.formatTime(world.roundTimeLeft.rounded(.up))
            timerLabel.fontColor = world.roundTimeLeft < 20 ? Palette.warning : UIStyle.accent
        }
        switch bomb.state {
        case .carried(let id):
            let carrier = world.soldier(id)
            bombLabel.text = attacking ? "Bomb carried by \(carrier?.isPlayer == true ? "you" : carrier?.name ?? "?")"
                                       : "Bomb not planted"
        case .dropped:
            bombLabel.text = attacking ? "Bomb dropped — pick it up!" : "Bomb not planted"
        case .planted:
            bombLabel.text = "Bomb planted on \(bomb.site?.name ?? "?")" + (bomb.defuserId != nil ? " — DEFUSING" : "")
        case .idle, .defused:
            bombLabel.text = "Bomb defused"
        case .exploded:
            bombLabel.text = "Bomb exploded"
        }
    }

    /// Rush: attacker tickets and the state of each station.
    private func updateRush(world: BattleWorld, attacking: Bool) {
        roleLabel.text = attacking ? "RUSH ATTACK — ARM AND DESTROY A AND B" : "RUSH DEFEND — PROTECT STATIONS A AND B"
        timerLabel.text = "TICKETS \(world.tickets)"
        timerLabel.fontColor = world.tickets < 20 ? Palette.warning : UIStyle.accent
        bombLabel.text = world.bombs.map { bomb -> String in
            let name = bomb.site?.name ?? "?"
            switch bomb.state {
            case .planted: return "\(name): ARMED \(Int(bomb.fuseLeft.rounded(.up)))s"
            case .exploded: return "\(name): destroyed"
            default: return "\(name): standing"
            }
        }.joined(separator: "   ")
    }
}

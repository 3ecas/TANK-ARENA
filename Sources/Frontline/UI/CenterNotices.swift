import SpriteKit

/// Centre-screen messages: respawn countdown, eliminated / spectating, reload.
@MainActor
final class CenterNotices {
    let root = SKNode()
    private let main = UIStyle.label("", size: 26, color: Palette.warning, bold: true, align: .center)
    private let sub = UIStyle.label("", size: 14, color: UIStyle.textColor, bold: true, align: .center)

    init() {
        main.position = CGPoint(x: 0, y: 140)
        sub.position = CGPoint(x: 0, y: 112)
        root.addChild(main)
        root.addChild(sub)
    }

    func update(player: Soldier, spectating: Soldier?) {
        if player.isAlive {
            main.text = ""
            sub.text = ""
        } else if player.isAwaitingRespawn {
            main.text = "RESPAWNING IN \(Int(player.respawnTimer.rounded(.up)))"
            sub.text = "This is your last life after this"
        } else {
            main.text = "ELIMINATED"
            sub.text = spectating.map { "Spectating \($0.name)" } ?? ""
        }
    }
}

import SpriteKit

/// Victory / defeat screen with a short summary.
@MainActor
final class GameOverOverlay {
    let root = SKNode()
    private let title = UIStyle.label("", size: 48, bold: true, align: .center)
    private let summary = UIStyle.label("", size: 15, align: .center)
    var onPlayAgain: (() -> Void)?
    var onMainMenu: (() -> Void)?

    init() {
        root.isHidden = true
        root.addChild(UIStyle.rect(size: CGSize(width: 6000, height: 6000), color: SKColor(white: 0, alpha: 0.6)))
        root.addChild(UIStyle.panel(size: CGSize(width: 520, height: 300)))
        title.position = CGPoint(x: 0, y: 90)
        summary.position = CGPoint(x: 0, y: 30)
        root.addChild(title)
        root.addChild(summary)
        let again = UIButton(title: "Play Again", size: CGSize(width: 200, height: 44), fontSize: 16)
        again.position = CGPoint(x: -110, y: -70)
        again.onClick = { [unowned self] in self.onPlayAgain?() }
        let menu = UIButton(title: "Main Menu", size: CGSize(width: 200, height: 44), fontSize: 16)
        menu.position = CGPoint(x: 110, y: -70)
        menu.onClick = { [unowned self] in self.onMainMenu?() }
        root.addChild(again)
        root.addChild(menu)
    }

    var isVisible: Bool { !root.isHidden }

    func show(victory: Bool, player: Hero, time: CGFloat) {
        root.isHidden = false
        title.text = victory ? "VICTORY" : "DEFEAT"
        title.fontColor = victory ? Palette.heal : Palette.warning
        summary.text = "Time \(UIStyle.formatTime(time))  ·  K/D/A \(player.kills)/\(player.deaths)/\(player.assists)"
            + "  ·  Level \(player.level)"
    }
}

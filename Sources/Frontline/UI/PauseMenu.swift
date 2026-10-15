import SpriteKit

/// Esc menu: resume, return to main menu, quit.
@MainActor
final class PauseMenu {
    let root = SKNode()
    var onResume: (() -> Void)?
    var onMainMenu: (() -> Void)?
    var onQuit: (() -> Void)?

    init() {
        root.isHidden = true
        let dim = UIStyle.rect(size: CGSize(width: 6000, height: 6000), color: SKColor(white: 0, alpha: 0.5))
        root.addChild(dim)
        root.addChild(UIStyle.panel(size: CGSize(width: 320, height: 280)))
        let title = UIStyle.label("PAUSED", size: 26, color: UIStyle.accent, bold: true, align: .center)
        title.position = CGPoint(x: 0, y: 95)
        root.addChild(title)
        let entries: [(String, () -> Void)] = [
            ("Resume", { [unowned self] in self.onResume?() }),
            ("Main Menu", { [unowned self] in self.onMainMenu?() }),
            ("Quit Game", { [unowned self] in self.onQuit?() }),
        ]
        for (index, entry) in entries.enumerated() {
            let button = UIButton(title: entry.0, size: CGSize(width: 220, height: 42), fontSize: 16)
            button.position = CGPoint(x: 0, y: 30 - CGFloat(index) * 56)
            button.onClick = entry.1
            root.addChild(button)
        }
    }

    var isVisible: Bool {
        get { !root.isHidden }
        set { root.isHidden = !newValue }
    }
}

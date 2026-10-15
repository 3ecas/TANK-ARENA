import SpriteKit

/// Centre-top announcements (kills, objectives, structures) and short feedback messages.
@MainActor
final class AnnouncementBanner {
    let root = SKNode()
    private let label = UIStyle.label("", size: 18, bold: true, align: .center)
    private let shadow = UIStyle.label("", size: 18, color: SKColor(white: 0, alpha: 0.7), bold: true, align: .center)
    private let messageLabel = UIStyle.label("", size: 14, color: Palette.warning, bold: true, align: .center)
    private var queue: [(String, SKColor)] = []
    private var timer: CGFloat = 0
    private var messageTimer: CGFloat = 0

    /// Feedback message position relative to the banner (set by HUD layout).
    var messageOffset: CGFloat = -300 { didSet { messageLabel.position = CGPoint(x: 0, y: messageOffset) } }

    init() {
        shadow.position = CGPoint(x: 2, y: -2)
        root.addChild(shadow)
        root.addChild(label)
        messageLabel.position = CGPoint(x: 0, y: messageOffset)
        root.addChild(messageLabel)
    }

    func announce(_ text: String, color: SKColor) {
        queue.append((text, color))
        if queue.count > 4 { queue.removeFirst() }
    }

    func showMessage(_ text: String) {
        messageLabel.text = text
        messageTimer = 2
    }

    func update(dt: CGFloat) {
        timer -= dt
        if timer <= 0 {
            if queue.isEmpty {
                label.text = ""
                shadow.text = ""
            } else {
                let (text, color) = queue.removeFirst()
                label.text = text
                label.fontColor = color
                shadow.text = text
                timer = 2.6
            }
        }
        label.alpha = timer > 0.5 ? 1 : Swift.max(0, timer / 0.5)
        shadow.alpha = label.alpha
        messageTimer -= dt
        messageLabel.alpha = messageTimer > 0.5 ? 1 : Swift.max(0, messageTimer / 0.5)
    }
}

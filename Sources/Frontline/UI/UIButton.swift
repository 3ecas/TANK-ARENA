import SpriteKit

/// Clickable rectangle with a title. Hit-testing is done by `UIHitTester`.
@MainActor
final class UIButton: SKNode {
    let size: CGSize
    private let background: SKShapeNode
    private let titleLabel: SKLabelNode
    var onClick: (() -> Void)?

    var isEnabled = true { didSet { refresh() } }
    var isSelected = false { didSet { refresh() } }
    var baseColor: SKColor { didSet { refresh() } }

    init(title: String, size: CGSize, fontSize: CGFloat = 14, color: SKColor? = nil) {
        self.size = size
        self.baseColor = color ?? UIStyle.buttonColor
        background = SKShapeNode(rectOf: size, cornerRadius: 5)
        background.lineWidth = 1.5
        titleLabel = UIStyle.label(title, size: fontSize, bold: true, align: .center)
        super.init()
        addChild(background)
        addChild(titleLabel)
        refresh()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    /// Whether a point in scene coordinates lies on this button.
    func hit(_ scenePoint: CGPoint, scene: SKScene) -> Bool {
        let local = convert(scenePoint, from: scene)
        return abs(local.x) <= size.width / 2 && abs(local.y) <= size.height / 2
    }

    private func refresh() {
        if !isEnabled {
            background.fillColor = UIStyle.buttonDisabled
        } else {
            background.fillColor = isSelected ? UIStyle.buttonHighlight : baseColor
        }
        background.strokeColor = isSelected ? UIStyle.accent : UIStyle.panelBorder
        titleLabel.fontColor = isEnabled ? UIStyle.textColor : UIStyle.dimText
    }
}

/// Finds the topmost enabled, visible button under a point.
@MainActor
enum UIHitTester {
    static func button(at scenePoint: CGPoint, in node: SKNode, scene: SKScene) -> UIButton? {
        guard !node.isHidden else { return nil }
        for child in node.children.reversed() {
            if let found = button(at: scenePoint, in: child, scene: scene) { return found }
        }
        if let button = node as? UIButton, button.isEnabled, button.hit(scenePoint, scene: scene) {
            return button
        }
        return nil
    }
}

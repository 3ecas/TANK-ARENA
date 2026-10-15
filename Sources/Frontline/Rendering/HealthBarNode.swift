import SpriteKit

/// Small HP bar drawn above units.
@MainActor
final class HealthBarNode: SKNode {
    private let background: SKSpriteNode
    private let fill: SKSpriteNode
    private let barColor: SKColor
    private let width: CGFloat

    init(width: CGFloat, height: CGFloat, color: SKColor) {
        self.width = width
        self.barColor = color
        background = SKSpriteNode(color: SKColor(white: 0, alpha: 0.65), size: CGSize(width: width + 2, height: height + 2))
        fill = SKSpriteNode(color: color, size: CGSize(width: width, height: height))
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position = CGPoint(x: -width / 2, y: 0)
        super.init()
        addChild(background)
        addChild(fill)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setFraction(_ fraction: CGFloat, invulnerable: Bool) {
        fill.xScale = fraction.clamped(0, 1)
        fill.color = invulnerable ? SKColor(white: 0.7, alpha: 1) : barColor
    }
}

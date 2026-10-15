import SpriteKit

/// Capture point ownership / progress and objective labels.
@MainActor
final class ObjectiveRenderer {
    private struct PointView {
        let ring: SKSpriteNode
        let progress: SKSpriteNode
    }

    private unowned let session: GameSession
    private var views: [CapturePointKind: PointView] = [:]

    init(layer: SKNode, session: GameSession) {
        self.session = session
        for point in session.world.capturePoints {
            let texture = EffectTextures.ring(radius: point.radius, lineWidth: 6)
            let ring = SKSpriteNode(texture: texture, size: TextureFactory.size(of: texture))
            ring.position = point.position
            ring.colorBlendFactor = 1
            let progress = SKSpriteNode(texture: EffectTextures.disc,
                                        size: CGSize(width: point.radius * 2, height: point.radius * 2))
            progress.position = point.position
            progress.colorBlendFactor = 1
            progress.alpha = 0.25
            layer.addChild(progress)
            layer.addChild(ring)
            layer.addChild(Self.label(point.kind.title.uppercased(), at: point.position + CGPoint(x: 0, y: point.radius + 18)))
            views[point.kind] = PointView(ring: ring, progress: progress)
        }
        layer.addChild(Self.label("HEAVY ARMOR DEPOT", at: ObjectiveConfig.depotPosition + CGPoint(x: 0, y: 250)))
    }

    func update() {
        for point in session.world.capturePoints {
            guard let view = views[point.kind] else { continue }
            view.ring.color = point.owner.map { Palette.team($0) } ?? SKColor(white: 0.85, alpha: 1)
            view.ring.alpha = point.capturingTeam == nil ? 0.8 : 1
            let leaning: Team = point.progress >= 0 ? .blue : .red
            view.progress.color = Palette.team(leaning)
            view.progress.setScale(Swift.max(0.01, abs(point.progress)))
        }
    }

    private static func label(_ text: String, at position: CGPoint) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = 14
        label.fontColor = SKColor(white: 1, alpha: 0.75)
        label.position = position
        label.verticalAlignmentMode = .center
        return label
    }
}

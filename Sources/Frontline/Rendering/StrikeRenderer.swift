import SpriteKit

/// Telegraphed warning zones for airstrikes / artillery / EMP. Always visible so they can be dodged.
@MainActor
final class StrikeRenderer {
    @MainActor
    private final class Marker {
        let root = SKNode()
        let fill: SKSpriteNode
        let core: SKSpriteNode
        init(fill: SKSpriteNode, core: SKSpriteNode) {
            self.fill = fill
            self.core = core
        }
    }

    private let layer: SKNode
    private unowned let session: GameSession
    private var markers: [Int: Marker] = [:]
    private var time: CGFloat = 0

    init(layer: SKNode, session: GameSession) {
        self.layer = layer
        self.session = session
    }

    func update(dt: CGFloat) {
        time += dt
        var live = Set<Int>()
        for strike in session.world.strikes where !strike.isDone {
            live.insert(strike.id)
            let marker = markers[strike.id] ?? makeMarker(for: strike)
            if strike.isWarning {
                marker.fill.alpha = 0.16 + 0.1 * abs(sin(time * 10))
                let progress = strike.warningProgress
                switch strike.shape {
                case .circle: marker.core.setScale(Swift.max(0.01, progress))
                case .line: marker.core.xScale = Swift.max(0.01, progress)
                }
            } else {
                marker.fill.alpha = 0.08
                marker.core.alpha = 0.1
            }
        }
        for (id, marker) in markers where !live.contains(id) {
            marker.root.removeFromParent()
            markers[id] = nil
        }
    }

    private func makeMarker(for strike: StrikeZone) -> Marker {
        let friendly = strike.team == session.player.team
        let color = friendly ? Palette.allyStrike : Palette.warning
        let marker: Marker
        switch strike.shape {
        case .circle(let center, let radius):
            let size = CGSize(width: radius * 2, height: radius * 2)
            marker = Marker(fill: tinted(EffectTextures.disc, size: size, color: color),
                            core: tinted(EffectTextures.disc, size: size, color: color))
            marker.root.position = center
            let ringTexture = EffectTextures.ring(radius: radius, lineWidth: 4)
            let ring = tinted(ringTexture, size: TextureFactory.size(of: ringTexture), color: color)
            ring.alpha = 0.9
            marker.root.addChild(ring)
        case .line(let from, let to, let width):
            let length = from.distance(to: to)
            let size = CGSize(width: length, height: width)
            marker = Marker(fill: tinted(EffectTextures.pixel, size: size, color: color),
                            core: tinted(EffectTextures.pixel, size: size, color: color))
            marker.root.position = from.lerp(to: to, t: 0.5)
            marker.root.zRotation = (to - from).angle
            marker.core.anchorPoint = CGPoint(x: 0, y: 0.5)
            marker.core.position = CGPoint(x: -length / 2, y: 0)
            for side in [-1.0, 1.0] as [CGFloat] {
                let edge = tinted(EffectTextures.pixel, size: CGSize(width: length, height: 3), color: color)
                edge.position = CGPoint(x: 0, y: side * width / 2)
                edge.alpha = 0.9
                marker.root.addChild(edge)
            }
        }
        marker.core.alpha = 0.3
        marker.root.addChild(marker.fill)
        marker.root.addChild(marker.core)
        layer.addChild(marker.root)
        markers[strike.id] = marker
        return marker
    }

    private func tinted(_ texture: SKTexture, size: CGSize, color: SKColor) -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture, size: size)
        node.color = color
        node.colorBlendFactor = 1
        return node
    }
}

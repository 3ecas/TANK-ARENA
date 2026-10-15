import SpriteKit

/// Top-left minimap: arena, teammates, visible enemies and the camera frame.
@MainActor
final class Minimap {
    static let width: CGFloat = 240
    let root = SKNode()
    private unowned let session: GameSession
    private let scale: CGFloat
    private let size: CGSize
    private let dotLayer = SKNode()
    private var dots: [SKSpriteNode] = []
    private let cameraFrame: SKShapeNode
    private var zoneMarkers: [SKShapeNode] = []
    private var frameSize: CGSize = .zero

    init(session: GameSession) {
        self.session = session
        let mapSize = session.world.map.size
        let scale = Minimap.width / mapSize.width
        let size = CGSize(width: mapSize.width * scale, height: mapSize.height * scale)
        self.scale = scale
        self.size = size
        let border = UIStyle.panel(size: CGSize(width: size.width + 8, height: size.height + 8))
        let terrain = SKSpriteNode(texture: ArenaPainter.texture(for: session.world.map), size: size)
        cameraFrame = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
        cameraFrame.strokeColor = SKColor(white: 1, alpha: 0.8)
        cameraFrame.lineWidth = 1
        dotLayer.zPosition = 1
        cameraFrame.zPosition = 2
        for node in [border, terrain, dotLayer, cameraFrame] as [SKNode] { root.addChild(node) }
        for zone in session.world.zones {
            let marker = SKShapeNode(circleOfRadius: zone.radius * scale)
            marker.lineWidth = 2
            marker.position = CGPoint(x: zone.center.x * scale - size.width / 2, y: zone.center.y * scale - size.height / 2)
            marker.zPosition = 0.5
            root.addChild(marker)
            zoneMarkers.append(marker)
        }
    }

    var mapSize: CGSize { size }

    func update(cameraRect: CGRect, renderer: WorldRenderer) {
        var used = 0
        for soldier in session.world.soldiers where renderer.isShown(soldier) {
            let node: SKSpriteNode
            if used < dots.count {
                node = dots[used]
            } else {
                node = SKSpriteNode(texture: EffectTextures.disc, size: CGSize(width: 5, height: 5))
                node.colorBlendFactor = 1
                dotLayer.addChild(node)
                dots.append(node)
            }
            used += 1
            node.isHidden = false
            node.color = soldier.isPlayer ? .white : Palette.team(soldier.team)
            let side: CGFloat = soldier.isPlayer ? 8 : 5
            node.size = CGSize(width: side, height: side)
            node.position = toMinimap(soldier.position)
        }
        for i in used..<dots.count { dots[i].isHidden = true }
        for (marker, zone) in zip(zoneMarkers, session.world.zones) {
            let color = zone.owner.map { Palette.team($0) } ?? SKColor(white: 0.9, alpha: 1)
            let active = zone.sector == session.world.sector
            marker.strokeColor = color.withAlphaComponent(active ? 1 : 0.35)
            marker.fillColor = color.withAlphaComponent(active ? 0.3 : 0.08)
            marker.lineWidth = active ? 2.5 : 1
        }
        let frame = CGSize(width: cameraRect.width * scale, height: cameraRect.height * scale)
        if frame != frameSize {
            frameSize = frame
            cameraFrame.path = CGPath(rect: CGRect(x: -frame.width / 2, y: -frame.height / 2,
                                                   width: frame.width, height: frame.height), transform: nil)
        }
        cameraFrame.position = toMinimap(CGPoint(x: cameraRect.midX, y: cameraRect.midY))
    }

    private func toMinimap(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x * scale - size.width / 2, y: p.y * scale - size.height / 2)
    }
}

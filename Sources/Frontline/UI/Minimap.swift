import SpriteKit

/// Bottom-right minimap: terrain, fog, units, structures, objectives, strike markers and camera frame.
/// Clicking it moves the camera.
@MainActor
final class Minimap {
    static let side: CGFloat = 210
    let root = SKNode()
    private unowned let session: GameSession
    private let fog: SKSpriteNode
    private let dotLayer = SKNode()
    private var dots: [SKSpriteNode] = []
    private var usedDots = 0
    private let cameraFrame: SKShapeNode
    private var cameraFrameSize: CGSize = .zero

    init(session: GameSession) {
        self.session = session
        let side = Minimap.side
        let border = UIStyle.panel(size: CGSize(width: side + 8, height: side + 8))
        let terrain = SKSpriteNode(texture: MapTextureBuilder.texture(for: session.world.map, city: session.world.city),
                                   size: CGSize(width: side, height: side))
        fog = SKSpriteNode(color: .clear, size: CGSize(width: side, height: side))
        cameraFrame = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
        cameraFrame.strokeColor = .white
        cameraFrame.lineWidth = 1.5
        for node in [border, terrain, fog, dotLayer, cameraFrame] as [SKNode] { root.addChild(node) }
    }

    /// Whether a point in the minimap's parent coordinates lies on it.
    func contains(_ point: CGPoint) -> Bool {
        let local = point - root.position
        return abs(local.x) <= Minimap.side / 2 && abs(local.y) <= Minimap.side / 2
    }

    /// Converts a point in the minimap's parent coordinates to a world position.
    func worldPoint(for point: CGPoint) -> CGPoint {
        let local = point - root.position
        let mapSize = session.world.map.size
        return CGPoint(x: (local.x / Minimap.side + 0.5) * mapSize, y: (local.y / Minimap.side + 0.5) * mapSize)
    }

    func update(cameraRect: CGRect, fogTexture: SKTexture?) {
        if let fogTexture = fogTexture, fog.texture !== fogTexture {
            fog.texture = fogTexture
            fog.color = .white
            fog.colorBlendFactor = 0
        }
        usedDots = 0
        let world = session.world
        let vision: VisionSystem = session.ctx.vision
        let team = session.player.team
        for point in world.capturePoints {
            dot(at: point.position, size: 12, color: point.owner.map { Palette.team($0) } ?? .white, round: true)
        }
        for strike in world.strikes where !strike.isDone {
            let color = strike.team == team ? Palette.allyStrike : Palette.warning
            dot(at: strike.shape.center, size: 16, color: color.withAlphaComponent(0.6), round: true)
        }
        for entity in world.entities where entity.isAlive && !entity.isRemoved && vision.canSee(team, entity) {
            let color: SKColor = entity === session.player ? .white
                : (entity.team == .neutral ? Palette.team(.neutral) : Palette.team(entity.team))
            if entity is Structure {
                dot(at: entity.position, size: (entity as? Structure)?.isHQ == true ? 12 : 8, color: color, round: false)
            } else if entity is Hero {
                dot(at: entity.position, size: entity === session.player ? 9 : 7, color: color, round: true)
            } else {
                dot(at: entity.position, size: 3, color: color, round: false)
            }
        }
        for i in usedDots..<dots.count { dots[i].isHidden = true }
        updateCameraFrame(cameraRect)
    }

    private func toMinimap(_ p: CGPoint) -> CGPoint {
        let mapSize = session.world.map.size
        return CGPoint(x: (p.x / mapSize - 0.5) * Minimap.side, y: (p.y / mapSize - 0.5) * Minimap.side)
    }

    private func dot(at position: CGPoint, size: CGFloat, color: SKColor, round: Bool) {
        let node: SKSpriteNode
        if usedDots < dots.count {
            node = dots[usedDots]
        } else {
            node = SKSpriteNode()
            dotLayer.addChild(node)
            dots.append(node)
        }
        usedDots += 1
        node.texture = round ? EffectTextures.disc : nil
        node.size = CGSize(width: size, height: size)
        node.color = color
        node.colorBlendFactor = 1
        node.position = toMinimap(position)
        node.isHidden = false
    }

    private func updateCameraFrame(_ rect: CGRect) {
        let scale = Minimap.side / session.world.map.size
        let size = CGSize(width: rect.width * scale, height: rect.height * scale)
        if size != cameraFrameSize {
            cameraFrameSize = size
            cameraFrame.path = CGPath(rect: CGRect(x: -size.width / 2, y: -size.height / 2,
                                                   width: size.width, height: size.height), transform: nil)
        }
        cameraFrame.position = toMinimap(CGPoint(x: rect.midX, y: rect.midY))
    }
}

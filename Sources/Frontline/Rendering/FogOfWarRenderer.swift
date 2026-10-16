import SpriteKit

/// Darkens the screen outside what the viewer (you, or the teammate you spectate) can see:
/// your own view cone clipped by walls. Bots' vision never affects the fog.
/// Drawn as a screen-sized texture each frame; the visible area gets a soft, feathered edge.
@MainActor
final class FogOfWarRenderer {
    let node = SKSpriteNode()

    init() {
        node.zPosition = 50
    }

    /// - Parameter flying: the viewer is in a helicopter and sees over walls.
    func update(viewer: Soldier?, cameraCenter: CGPoint, viewSize: CGSize, map: ArenaMap, flying: Bool = false) {
        guard let viewer = viewer, viewer.isAlive, viewSize.width > 1, viewSize.height > 1 else {
            node.isHidden = true
            return
        }
        node.isHidden = false
        let polygon = VisibilityPolygon.compute(
            origin: viewer.position, facing: viewer.facing, fieldOfView: VisionSystem.fieldOfView(for: viewer),
            range: GameConfig.visionRange, peripheral: GameConfig.peripheralRadius, map: map,
            rays: GameConfig.fogRayCount, ignoreWalls: flying)
        // Screen space: camera centre is the middle of the view.
        let origin = CGPoint(x: cameraCenter.x - viewSize.width / 2, y: cameraCenter.y - viewSize.height / 2)
        let blind = viewer.isBlind
        let image = TextureFactory.renderImage(size: viewSize, scale: GameConfig.fogResolution) { ctx, size in
            ctx.setFillColor(Palette.rgb(0.02, 0.02, 0.03, GameConfig.fogAlpha))
            ctx.fill(CGRect(origin: .zero, size: size))
            guard !blind, let first = polygon.first else { return }
            let path = CGMutablePath()
            path.move(to: first - origin)
            for point in polygon.dropFirst() { path.addLine(to: point - origin) }
            path.closeSubpath()
            // Cut the visible area out, then feather its edge with a few soft strokes.
            ctx.setBlendMode(.destinationOut)
            ctx.addPath(path)
            ctx.setFillColor(Palette.rgb(0, 0, 0, 1))
            ctx.fillPath()
            ctx.setLineJoin(.round)
            for (width, alpha) in GameConfig.fogFeather {
                ctx.addPath(path)
                ctx.setStrokeColor(Palette.rgb(0, 0, 0, alpha))
                ctx.setLineWidth(width)
                ctx.strokePath()
            }
        }
        guard let cgImage = image else { return }
        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .linear
        node.texture = texture
        node.size = viewSize
    }
}

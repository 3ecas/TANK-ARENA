import SpriteKit

/// Darkens the screen outside what the viewer's team can see: the viewer's view cone plus every
/// nearby teammate's cone (shared team vision), clipped by walls.
/// Drawn as a small screen-sized texture each frame and stretched with smooth filtering.
@MainActor
final class FogOfWarRenderer {
    let node = SKSpriteNode()

    init() {
        node.zPosition = 50
    }

    func update(viewer: Soldier?, allies: [Soldier], cameraCenter: CGPoint, viewSize: CGSize, map: ArenaMap) {
        guard let viewer = viewer, viewer.isAlive, viewSize.width > 1, viewSize.height > 1 else {
            node.isHidden = true
            return
        }
        node.isHidden = false
        var polygons = [VisibilityPolygon.compute(
            origin: viewer.position, facing: viewer.facing, fieldOfView: VisionSystem.fieldOfView(for: viewer),
            range: GameConfig.visionRange, peripheral: GameConfig.peripheralRadius, map: map,
            rays: GameConfig.fogRayCount)]
        // Teammates whose cone can reach the screen.
        let reach = GameConfig.visionRange + Swift.max(viewSize.width, viewSize.height) * 0.75
        for ally in allies where ally !== viewer && ally.isAlive && ally.team == viewer.team
            && ally.position.distance(to: cameraCenter) < reach {
            polygons.append(VisibilityPolygon.compute(
                origin: ally.position, facing: ally.facing, fieldOfView: VisionSystem.fieldOfView(for: ally),
                range: GameConfig.visionRange, peripheral: GameConfig.peripheralRadius, map: map,
                rays: GameConfig.fogAllyRayCount))
        }
        // Screen space: camera centre is the middle of the view.
        let origin = CGPoint(x: cameraCenter.x - viewSize.width / 2, y: cameraCenter.y - viewSize.height / 2)
        let blind = viewer.isBlind
        let image = TextureFactory.renderImage(size: viewSize, scale: GameConfig.fogResolution) { ctx, size in
            ctx.setFillColor(Palette.rgb(0.02, 0.02, 0.03, GameConfig.fogAlpha))
            ctx.fill(CGRect(origin: .zero, size: size))
            guard !blind else { return }
            ctx.setBlendMode(.clear)
            for polygon in polygons {
                guard let first = polygon.first else { continue }
                ctx.beginPath()
                ctx.move(to: first - origin)
                for point in polygon.dropFirst() { ctx.addLine(to: point - origin) }
                ctx.closePath()
                ctx.fillPath()
            }
        }
        guard let cgImage = image else { return }
        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .linear
        node.texture = texture
        node.size = viewSize
    }
}

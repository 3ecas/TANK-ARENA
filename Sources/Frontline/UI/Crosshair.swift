import SpriteKit

/// Crosshair following the mouse, with a hit marker when the player lands a shot.
@MainActor
final class Crosshair {
    let root = SKNode()
    private let reticle: SKSpriteNode
    private let hitMarker: SKSpriteNode
    private var hitTime: CGFloat = 0

    init() {
        reticle = TextureFactory.sprite(EffectTextures.reticle)
        reticle.colorBlendFactor = 1
        reticle.color = SKColor(white: 1, alpha: 1)
        hitMarker = TextureFactory.sprite(EffectTextures.reticle)
        hitMarker.colorBlendFactor = 1
        hitMarker.color = Palette.warning
        hitMarker.zRotation = .pi / 4
        hitMarker.isHidden = true
        root.addChild(reticle)
        root.addChild(hitMarker)
    }

    func showHit() {
        hitTime = 0.15
    }

    func update(dt: CGFloat, screenPosition: CGPoint, spreadScale: CGFloat) {
        root.position = screenPosition
        reticle.setScale(0.8 + spreadScale)
        hitTime -= dt
        hitMarker.isHidden = hitTime <= 0
    }
}

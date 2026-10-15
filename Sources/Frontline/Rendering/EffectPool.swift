import SpriteKit

/// Recycled sprites animated by hand each frame (no per-effect SKActions or closures).
@MainActor
final class EffectPool {
    private struct Active {
        let node: SKSpriteNode
        var age: CGFloat
        let life: CGFloat
        var velocity: CGPoint
        let startScale: CGFloat
        let endScale: CGFloat
        let startAlpha: CGFloat
        let drag: CGFloat
        let spin: CGFloat
    }

    let layer: SKNode
    private let maxActive: Int
    private var active: [Active] = []
    private var free: [SKSpriteNode] = []

    init(layer: SKNode, maxActive: Int = 700) {
        self.layer = layer
        self.maxActive = maxActive
    }

    var isSaturated: Bool { active.count >= maxActive }

    @discardableResult
    func spawn(_ texture: SKTexture, at position: CGPoint, size: CGSize, color: SKColor? = nil,
               alpha: CGFloat = 1, life: CGFloat, velocity: CGPoint = .zero, startScale: CGFloat = 1,
               endScale: CGFloat = 1, rotation: CGFloat = 0, drag: CGFloat = 0, spin: CGFloat = 0,
               additive: Bool = false) -> SKSpriteNode? {
        guard !isSaturated else { return nil }
        let node = free.popLast() ?? makeNode()
        node.texture = texture
        node.size = size
        node.position = position
        node.zRotation = rotation
        node.alpha = alpha
        node.setScale(startScale)
        node.isHidden = false
        node.blendMode = additive ? .add : .alpha
        if let color = color {
            node.color = color
            node.colorBlendFactor = 1
        } else {
            node.colorBlendFactor = 0
        }
        active.append(Active(node: node, age: 0, life: Swift.max(life, 0.01), velocity: velocity,
                             startScale: startScale, endScale: endScale, startAlpha: alpha, drag: drag, spin: spin))
        return node
    }

    func update(dt: CGFloat) {
        var i = 0
        while i < active.count {
            active[i].age += dt
            let effect = active[i]
            if effect.age >= effect.life {
                effect.node.isHidden = true
                free.append(effect.node)
                active.swapAt(i, active.count - 1)
                active.removeLast()
                continue
            }
            let t = effect.age / effect.life
            effect.node.position += effect.velocity * dt
            effect.node.zRotation += effect.spin * dt
            active[i].velocity = effect.velocity * Swift.max(0, 1 - effect.drag * dt)
            effect.node.setScale(effect.startScale + (effect.endScale - effect.startScale) * t)
            effect.node.alpha = effect.startAlpha * (1 - t * t)
            i += 1
        }
    }

    private func makeNode() -> SKSpriteNode {
        let node = SKSpriteNode()
        layer.addChild(node)
        return node
    }
}

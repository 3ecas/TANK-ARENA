import SpriteKit

/// Floating combat text (damage, heals, gold, level up) using recycled labels.
@MainActor
final class FloatingTextLayer {
    private struct Active {
        let label: SKLabelNode
        var age: CGFloat
        let life: CGFloat
        let rise: CGFloat
    }

    let layer = SKNode()
    private var active: [Active] = []
    private var free: [SKLabelNode] = []
    private let maxActive = 80

    func spawn(_ text: String, at position: CGPoint, color: SKColor, fontSize: CGFloat = 14,
               life: CGFloat = 0.9, rise: CGFloat = 46) {
        guard active.count < maxActive else { return }
        let label = free.popLast() ?? makeLabel()
        label.text = text
        label.fontColor = color
        label.fontSize = fontSize
        label.position = position + CGPoint(x: CGFloat.random(in: -10...10), y: 14)
        label.alpha = 1
        label.isHidden = false
        active.append(Active(label: label, age: 0, life: life, rise: rise))
    }

    func update(dt: CGFloat) {
        var i = 0
        while i < active.count {
            active[i].age += dt
            let item = active[i]
            if item.age >= item.life {
                item.label.isHidden = true
                free.append(item.label)
                active.swapAt(i, active.count - 1)
                active.removeLast()
                continue
            }
            let t = item.age / item.life
            item.label.position.y += item.rise * dt / item.life
            item.label.alpha = t < 0.6 ? 1 : 1 - (t - 0.6) / 0.4
            i += 1
        }
    }

    private func makeLabel() -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        layer.addChild(label)
        return label
    }
}

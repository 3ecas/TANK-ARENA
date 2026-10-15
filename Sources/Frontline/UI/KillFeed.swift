import SpriteKit

/// Top-right list of recent kills: "Killer [weapon] Victim".
@MainActor
final class KillFeed {
    private struct Entry {
        let label: SKLabelNode
        var age: CGFloat
    }

    let root = SKNode()
    private var entries: [Entry] = []
    private let maxEntries = 6
    private let lifetime: CGFloat = 6

    func add(killer: Soldier?, victim: Soldier, weapon: String, playerTeam: Team) {
        let killerName = killer?.name ?? "World"
        let label = UIStyle.label("\(killerName)  [\(weapon)]  \(victim.name)", size: 12, bold: true, align: .right)
        let involvesPlayer = killer?.isPlayer == true || victim.isPlayer
        label.fontColor = involvesPlayer ? UIStyle.accent
            : (victim.team == playerTeam ? Palette.team(.red) : Palette.team(.blue))
        root.addChild(label)
        entries.insert(Entry(label: label, age: 0), at: 0)
        while entries.count > maxEntries { entries.removeLast().label.removeFromParent() }
        layout()
    }

    func update(dt: CGFloat) {
        for i in entries.indices { entries[i].age += dt }
        let expired = entries.filter { $0.age > lifetime }
        guard !expired.isEmpty else { return }
        for entry in expired { entry.label.removeFromParent() }
        entries.removeAll { $0.age > lifetime }
        layout()
    }

    private func layout() {
        for (index, entry) in entries.enumerated() {
            entry.label.position = CGPoint(x: 0, y: -CGFloat(index) * 18)
        }
    }
}

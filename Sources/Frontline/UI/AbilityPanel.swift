import SpriteKit

/// Above the vitals panel: your class, what Q does right now (call in an earned vehicle, or the class
/// ability with its cooldown) and your current killstreak toward the next vehicle.
@MainActor
final class AbilityPanel {
    static let size = CGSize(width: 260, height: 58)
    let root = SKNode()
    private let classLabel = UIStyle.label("", size: 12, color: UIStyle.dimText, bold: true)
    private let abilityLabel = UIStyle.label("", size: 14, bold: true)
    private let streakLabel = UIStyle.label("", size: 11, color: UIStyle.dimText)

    init() {
        root.addChild(UIStyle.panel(size: AbilityPanel.size))
        let left = -AbilityPanel.size.width / 2 + 12
        classLabel.position = CGPoint(x: left, y: 14)
        abilityLabel.position = CGPoint(x: left, y: -4)
        streakLabel.position = CGPoint(x: left, y: -21)
        for node in [classLabel, abilityLabel, streakLabel] { root.addChild(node) }
    }

    func update(soldier: Soldier, world: BattleWorld) {
        classLabel.text = soldier.soldierClass.displayName.uppercased()
            + (soldier.soldierClass == .medic ? "  ·  hold E on downed allies" : "")
        if let vehicle = world.vehicle(of: soldier) {
            abilityLabel.text = "Driving \(vehicle.kind.displayName.lowercased())  \(Int(vehicle.hp))/\(Int(vehicle.maxHP))"
            abilityLabel.fontColor = UIStyle.accent
        } else if let reward = soldier.reward {
            abilityLabel.text = world.vehiclesAllowed ? "Q  CALL IN \(reward.displayName.uppercased())!"
                                                      : "\(reward.displayName) earned (sectors 3–5)"
            abilityLabel.fontColor = world.vehiclesAllowed ? Palette.heal : UIStyle.dimText
        } else if soldier.abilityCooldown > 0 {
            abilityLabel.text = "Q  \(soldier.soldierClass.abilityName)  \(Int(soldier.abilityCooldown.rounded(.up)))s"
            abilityLabel.fontColor = UIStyle.dimText
        } else {
            abilityLabel.text = "Q  \(soldier.soldierClass.abilityName)"
            abilityLabel.fontColor = UIStyle.textColor
        }
        if world.mode == .rush {
            let next = soldier.killStreak < VehicleConfig.tankStreak
                ? "tank at \(VehicleConfig.tankStreak)" : "helicopter at \(VehicleConfig.helicopterStreak)"
            streakLabel.text = "Streak \(soldier.killStreak)" + (soldier.killStreak < VehicleConfig.helicopterStreak ? "  (\(next))" : "")
        } else {
            streakLabel.text = ""
        }
    }
}

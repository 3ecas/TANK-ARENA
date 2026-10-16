import CoreGraphics

/// Spawns both teams (the player plus the blue bots against the red bots, sized by the mode). In bomb mode the
/// bomb goes to an attacker: the player when attacking, otherwise a random attacking bot.
@MainActor
enum BattleSetup {
    /// Bot classes cycle so every team has a mix: assault, medic, engineer, assault, then random.
    private static func botClass(_ index: Int) -> SoldierClass {
        switch index % 5 {
        case 0, 3: return .assault
        case 1: return .medic
        case 2: return .engineer
        default: return SoldierClass.allCases.randomElement() ?? .assault
        }
    }

    static func populate(_ world: BattleWorld, playerClass: SoldierClass) {
        for team in Team.playable {
            for index in 0..<world.mode.teamSize {
                let isPlayer = team == .blue && index == 0
                let soldier = Soldier(
                    id: world.makeId(), team: team, name: RosterNames.name(team: team, index: index),
                    isPlayer: isPlayer, soldierClass: isPlayer ? playerClass : botClass(index + (team == .blue ? 0 : 1)),
                    position: world.randomSpawnPoint(team),
                    primary: WeaponCatalog.randomPrimary(), grenade: GrenadeType.allCases.randomElement() ?? .frag)
                soldier.respawnsLeft = world.mode.respawns
                soldier.facing = team == world.attackers ? 0 : .pi
                soldier.aimPoint = soldier.position + CGPoint(angle: soldier.facing, length: 100)
                world.add(soldier)
            }
        }
        guard world.mode == .bomb else { return }
        let attackers = world.soldiers(of: world.attackers)
        if let carrier = attackers.first(where: { $0.isPlayer }) ?? attackers.randomElement() {
            world.bomb.state = .carried(by: carrier.id)
            world.bomb.position = carrier.position
        }
    }
}

import CoreGraphics

/// Spawns both teams: the player plus 24 blue bots against 25 red bots.
@MainActor
enum BattleSetup {
    static func populate(_ world: BattleWorld) {
        for team in Team.playable {
            for index in 0..<GameConfig.teamSize {
                let isPlayer = team == .blue && index == 0
                let soldier = Soldier(
                    id: world.makeId(), team: team, name: RosterNames.name(team: team, index: index),
                    isPlayer: isPlayer, position: world.randomSpawnPoint(team),
                    primary: WeaponCatalog.randomPrimary(), grenade: GrenadeType.allCases.randomElement() ?? .frag)
                soldier.facing = team == world.attackers ? 0 : .pi
                soldier.aimPoint = soldier.position + CGPoint(angle: soldier.facing, length: 100)
                world.add(soldier)
            }
        }
    }
}

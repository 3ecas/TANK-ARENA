import CoreGraphics

/// Spawns both teams (the player plus 4 blue bots against 5 red bots) and gives the bomb to an attacker:
/// the player when attacking, otherwise a random attacking bot.
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
        let attackers = world.soldiers(of: world.attackers)
        if let carrier = attackers.first(where: { $0.isPlayer }) ?? attackers.randomElement() {
            world.bomb.state = .carried(by: carrier.id)
            world.bomb.position = carrier.position
        }
    }
}

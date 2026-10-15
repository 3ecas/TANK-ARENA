/// Maps ability ids to their implementations.
@MainActor
struct AbilityRegistry {
    private let abilities: [AbilityID: Ability]

    init() {
        let all: [Ability] = [
            FragGrenadeAbility(), StimAbility(), DeployShieldAbility(), SmokeGrenadeAbility(),
            MedkitAbility(), UAVReconAbility(), SupplyDropAbility(), SentryTurretAbility(),
            StrafingRunAbility(), CarpetBombingAbility(), ArtilleryBarrageAbility(), EMPStrikeAbility(),
            CallTankAbility(), ReinforcementsAbility(), AttackHelicopterAbility(),
        ]
        var table: [AbilityID: Ability] = [:]
        for ability in all { table[ability.id] = ability }
        abilities = table
    }

    func ability(for id: AbilityID) -> Ability? { abilities[id] }
}

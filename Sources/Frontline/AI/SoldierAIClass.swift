import CoreGraphics

/// Class and killstreak decisions for bots: call in an earned vehicle as soon as it is allowed, drop health /
/// ammo boxes where teammates need them, sprint into fights, and (medics) revive downed teammates.
extension SoldierAI {
    /// Called on each think step: decides whether to press Q.
    func considerAbility() {
        guard !soldier.isMounted else { return }
        let world = ctx.world
        if let reward = soldier.reward, world.vehiclesAllowed {
            let outside = world.map.outdoorStartX.map { soldier.position.x >= $0 } ?? true
            if !hasRecentThreat && outside {
                let limit = reward == .tank ? VehicleConfig.tanksPerTeam : VehicleConfig.helicoptersPerTeam
                let active = world.vehicles.filter { $0.isAlive && $0.team == soldier.team && $0.kind == reward }.count
                if active < limit { soldier.wantsAbility = true }
            }
            return
        }
        guard soldier.abilityCooldown <= 0 else { return }
        let mates = world.soldiers.filter {
            $0.isAlive && !$0.isMounted && $0.team == soldier.team && $0.position.distance(to: soldier.position) < 220
        }
        switch soldier.soldierClass {
        case .assault:
            // Adrenaline when closing in on a fight.
            if hasRecentThreat && targetId == nil { soldier.wantsAbility = true }
        case .medic:
            if mates.contains(where: { $0.hp < GameConfig.maxHp * 0.6 }) { soldier.wantsAbility = true }
        case .engineer:
            let lowAmmo = mates.contains { mate in
                mate.weapons[0].reserve.map { $0 < mate.weapons[0].def.magSize } ?? false
            }
            if lowAmmo || (mates.count >= 3 && !hasRecentThreat) { soldier.wantsAbility = true }
        }
    }

    /// Medics: the nearest free medic runs to a downed teammate and holds E to revive them.
    func reviveDuty(dt: CGFloat) -> Bool {
        guard soldier.soldierClass == .medic, targetId == nil else { return false }
        let world = ctx.world
        let downed = world.soldiers.filter {
            $0.isDowned && $0.team == soldier.team && $0.position.distance(to: soldier.position) < AIConfig.reviveReach
        }
        guard let patient = downed.min(by: { $0.position.distance(to: soldier.position) < $1.position.distance(to: soldier.position) }) else {
            return false
        }
        if soldier.position.distance(to: patient.position) <= ClassConfig.reviveRadius * 0.7 {
            soldier.moveDir = .zero
            soldier.wantsToFire = false
            soldier.wantsToInteract = true
            soldier.aimPoint = patient.position
            return true
        }
        let nearestMedic = world.soldiers
            .filter { $0.isAlive && !$0.isMounted && !$0.isPlayer && $0.team == soldier.team && $0.soldierClass == .medic && !$0.isEngaged }
            .min { $0.position.distance(to: patient.position) < $1.position.distance(to: patient.position) }
        guard nearestMedic === soldier, !hasRecentThreat else { return false }
        travelGoal = patient.position
        moveToward(world.nav.nearestWalkable(patient.position), dt: dt)
        if soldier.moveDir.lengthSquared > 0.01 { soldier.aimPoint = soldier.position + soldier.moveDir * 200 }
        return true
    }
}

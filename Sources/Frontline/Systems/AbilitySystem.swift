import CoreGraphics

/// Q: calls in an earned vehicle (rush sectors 3–5, team limits apply); otherwise the class ability —
/// assault adrenaline, medic health box, engineer ammo box — on a cooldown.
@MainActor
final class AbilitySystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        for soldier in ctx.world.soldiers where soldier.isAlive {
            soldier.abilityCooldown = Swift.max(0, soldier.abilityCooldown - dt)
            soldier.sprintTime = Swift.max(0, soldier.sprintTime - dt)
            guard soldier.wantsAbility else { continue }
            soldier.wantsAbility = false
            guard !soldier.isMounted else { continue }
            // An earned vehicle takes Q where vehicles are allowed; elsewhere Q stays the class ability.
            if let reward = soldier.reward, ctx.world.vehiclesAllowed {
                if let problem = callProblem(reward, for: soldier) {
                    ctx.bus.publish(.abilityFailed(soldierId: soldier.id, reason: problem))
                } else {
                    call(reward, for: soldier)
                }
                continue
            }
            useClassAbility(soldier)
        }
    }

    /// Why a vehicle can't be called in right now (nil = it can).
    func callProblem(_ kind: VehicleKind, for soldier: Soldier) -> String? {
        let world = ctx.world
        let team = soldier.team
        guard world.vehiclesAllowed else { return "Vehicles only in the open sectors (3–5)" }
        if let outdoor = world.map.outdoorStartX, soldier.position.x < outdoor {
            return "Get out of the building to call in a vehicle"
        }
        let limit = kind == .tank ? VehicleConfig.tanksPerTeam : VehicleConfig.helicoptersPerTeam
        let active = world.vehicles.filter { $0.isAlive && $0.team == team && $0.kind == kind }.count
        return active >= limit ? "Your team already has \(limit) \(kind.displayName.lowercased())\(limit > 1 ? "s" : "")" : nil
    }

    private func call(_ kind: VehicleKind, for soldier: Soldier) {
        let world = ctx.world
        let position = kind == .tank ? world.vehicleNav.nearestWalkable(soldier.position) : soldier.position
        let vehicle = Vehicle(id: world.makeId(), kind: kind, team: soldier.team, position: position,
                              facing: soldier.facing, pilotId: soldier.id)
        world.vehicles.append(vehicle)
        soldier.vehicleId = vehicle.id
        soldier.reward = nil
        soldier.wantsToInteract = false
        ctx.bus.publish(.vehicleCalled(soldierId: soldier.id, kind: kind))
    }

    private func useClassAbility(_ soldier: Soldier) {
        guard soldier.abilityCooldown <= 0 else {
            ctx.bus.publish(.abilityFailed(soldierId: soldier.id, reason: "\(soldier.soldierClass.abilityName) ready in \(Int(soldier.abilityCooldown.rounded(.up)))s"))
            return
        }
        soldier.abilityCooldown = ClassConfig.abilityCooldown
        switch soldier.soldierClass {
        case .assault:
            soldier.sprintTime = ClassConfig.sprintTime
        case .medic:
            dropBox(.health, by: soldier)
        case .engineer:
            dropBox(.ammo, by: soldier)
        }
        ctx.bus.publish(.abilityUsed(soldierId: soldier.id, name: soldier.soldierClass.abilityName))
    }

    private func dropBox(_ kind: SupplyBox.Kind, by soldier: Soldier) {
        let world = ctx.world
        let spot = world.nav.nearestWalkable(soldier.position + CGPoint(angle: soldier.facing, length: 24))
        world.boxes.append(SupplyBox(id: world.makeId(), kind: kind, team: soldier.team, position: spot))
    }
}

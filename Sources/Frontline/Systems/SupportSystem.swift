import CoreGraphics

/// Supply boxes heal or re-arm teammates standing near them; downed soldiers bleed out unless a medic
/// holds E next to them long enough to revive them.
@MainActor
final class SupportSystem {
    unowned let ctx: BattleContext

    init(ctx: BattleContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        let world = ctx.world
        for box in world.boxes {
            box.timeLeft -= dt
            for soldier in world.soldiers where soldier.isAlive && !soldier.isMounted && soldier.team == box.team
                && soldier.position.distance(to: box.position) <= ClassConfig.boxRadius {
                supply(soldier, from: box, dt: dt)
            }
        }
        for soldier in world.soldiers where soldier.isDowned {
            soldier.downedTime = Swift.max(0, soldier.downedTime - dt)
            updateRevive(soldier, dt: dt)
        }
    }

    private func supply(_ soldier: Soldier, from box: SupplyBox, dt: CGFloat) {
        switch box.kind {
        case .health:
            soldier.hp = Swift.min(GameConfig.maxHp, soldier.hp + ClassConfig.healPerSecond * dt)
        case .ammo:
            soldier.ammoTimer += dt
            guard soldier.ammoTimer >= ClassConfig.ammoInterval else { return }
            soldier.ammoTimer = 0
            for index in soldier.weapons.indices {
                guard let max = soldier.weapons[index].maxReserve, let reserve = soldier.weapons[index].reserve else { continue }
                soldier.weapons[index].reserve = Swift.min(max, reserve + soldier.weapons[index].def.magSize)
            }
            soldier.grenadeCount = Swift.min(soldier.soldierClass.grenades, soldier.grenadeCount + 1)
        }
    }

    private func updateRevive(_ downed: Soldier, dt: CGFloat) {
        let world = ctx.world
        let medic = world.soldiers.first {
            $0.isAlive && !$0.isMounted && $0.team == downed.team && $0.soldierClass == .medic && $0.wantsToInteract
                && $0.position.distance(to: downed.position) <= ClassConfig.reviveRadius
        }
        guard let reviver = medic, downed.downedTime > 0 else {
            downed.reviveProgress = 0
            return
        }
        reviver.moveDir = .zero
        reviver.wantsToFire = false
        downed.reviveProgress += dt / ClassConfig.reviveTime
        guard downed.reviveProgress >= 1 else { return }
        downed.hp = ClassConfig.reviveHealth
        downed.downedTime = 0
        downed.reviveProgress = 0
        downed.respawnTimer = 0
        downed.spawnProtection = 1
        reviver.wantsToInteract = false
        ctx.bus.publish(.soldierRevived(soldierId: downed.id, byId: reviver.id))
    }
}

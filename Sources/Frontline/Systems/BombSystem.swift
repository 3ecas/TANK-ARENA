import CoreGraphics

/// Every bomb, every frame. Bomb mode: the bomb follows its carrier, drops where the carrier dies, is picked
/// up by attackers and planted by holding E inside a site. Rush: any attacker holding E next to an idle station
/// arms it. Armed bombs tick for 45 s; a defender holding E next to one defuses it (a rush station can then
/// be armed again). Planting, arming or defusing roots the soldier in place.
@MainActor
final class BombSystem {
    unowned let ctx: BattleContext
    private let damage: DamageSystem

    init(ctx: BattleContext, damage: DamageSystem) {
        self.ctx = ctx
        self.damage = damage
    }

    func update(dt: CGFloat) {
        for bomb in ctx.world.bombs {
            switch bomb.state {
            case .idle: updateStation(bomb, dt: dt)
            case .carried(let id): updateCarried(bomb, carrierId: id, dt: dt)
            case .dropped: pickUp(bomb)
            case .planted: updatePlanted(bomb, dt: dt)
            case .defused, .exploded: break
            }
        }
    }

    private func updateCarried(_ bomb: Bomb, carrierId: Int, dt: CGFloat) {
        guard let carrier = ctx.world.soldier(carrierId), carrier.isAlive else {
            bomb.state = .dropped
            bomb.plantProgress = 0
            bomb.armerId = nil
            ctx.bus.publish(.bombDropped(position: bomb.position))
            return
        }
        bomb.position = carrier.position
        guard carrier.wantsToInteract, let site = ctx.world.sites.first(where: { $0.contains(carrier.position) }) else {
            bomb.plantProgress = 0
            bomb.armerId = nil
            return
        }
        advancePlant(bomb, by: carrier, site: site, dt: dt)
    }

    /// Rush station: armed by any attacker standing next to it and holding E.
    private func updateStation(_ bomb: Bomb, dt: CGFloat) {
        let world = ctx.world
        guard let site = bomb.site, let armer = world.soldiers.first(where: {
            $0.isAlive && $0.team == world.attackers && $0.wantsToInteract
                && $0.position.distance(to: bomb.position) <= BombConfig.armRadius
        }) else {
            bomb.plantProgress = 0
            bomb.armerId = nil
            return
        }
        advancePlant(bomb, by: armer, site: site, dt: dt)
    }

    private func advancePlant(_ bomb: Bomb, by soldier: Soldier, site: BombSite, dt: CGFloat) {
        root(soldier)
        if bomb.armerId != soldier.id {
            bomb.armerId = soldier.id
            bomb.plantProgress = 0
        }
        bomb.plantProgress += dt / BombConfig.plantTime
        guard bomb.plantProgress >= 1 else { return }
        if bomb.carrierId != nil { bomb.position = soldier.position }
        bomb.state = .planted
        bomb.site = site
        bomb.fuseLeft = BombConfig.fuseTime
        bomb.plantProgress = 0
        bomb.armerId = nil
        soldier.wantsToInteract = false
        ctx.bus.publish(.bombPlanted(site: site.name, planterId: soldier.id))
        ctx.bus.publish(.announcement(text: ctx.world.mode == .rush ? "Station \(site.name) armed!" : "Bomb planted on site \(site.name)!"))
    }

    private func pickUp(_ bomb: Bomb) {
        let world = ctx.world
        guard let taker = world.soldiers.first(where: {
            $0.isAlive && $0.team == world.attackers && $0.position.distance(to: bomb.position) <= BombConfig.pickupRadius
        }) else { return }
        bomb.state = .carried(by: taker.id)
        ctx.bus.publish(.bombPickedUp(soldierId: taker.id))
    }

    private func updatePlanted(_ bomb: Bomb, dt: CGFloat) {
        let world = ctx.world
        bomb.fuseLeft -= dt
        if bomb.fuseLeft <= 0 {
            explode(bomb)
            return
        }
        let current = world.soldier(bomb.defuserId).flatMap { canDefuse($0, bomb) ? $0 : nil }
        guard let defuser = current ?? world.soldiers.first(where: { canDefuse($0, bomb) }) else {
            bomb.defuserId = nil
            bomb.defuseProgress = 0
            return
        }
        if defuser.id != bomb.defuserId {
            bomb.defuserId = defuser.id
            bomb.defuseProgress = 0
        }
        root(defuser)
        bomb.defuseProgress += dt / BombConfig.defuseTime
        guard bomb.defuseProgress >= 1 else { return }
        // A rush station can be armed again; the bomb-mode bomb is done.
        bomb.state = world.mode == .rush ? .idle : .defused
        bomb.defuserId = nil
        bomb.defuseProgress = 0
        defuser.wantsToInteract = false
        ctx.bus.publish(.bombDefused(defuserId: defuser.id))
        let name = bomb.site?.name ?? ""
        ctx.bus.publish(.announcement(text: world.mode == .rush ? "Station \(name) defused!" : "Bomb defused!"))
    }

    private func canDefuse(_ soldier: Soldier, _ bomb: Bomb) -> Bool {
        soldier.isAlive && soldier.team == ctx.world.defenders && soldier.wantsToInteract
            && soldier.position.distance(to: bomb.position) <= BombConfig.defuseRadius
    }

    /// Planting / defusing: no walking, no shooting.
    private func root(_ soldier: Soldier) {
        soldier.moveDir = .zero
        soldier.wantsToFire = false
        soldier.firePressed = false
    }

    private func explode(_ bomb: Bomb) {
        bomb.state = .exploded
        let kill = BombConfig.killRadius, blast = BombConfig.blastRadius
        for soldier in ctx.world.soldiers where soldier.isAlive {
            let distance = soldier.position.distance(to: bomb.position)
            guard distance <= blast else { continue }
            let falloff = distance <= kill ? 1 : 1 - (distance - kill) / (blast - kill)
            damage.apply(BombConfig.blastDamage * falloff, to: soldier, from: nil, weaponName: "Bomb")
        }
        ctx.bus.publish(.grenadeExploded(type: .frag, position: bomb.position, radius: blast))
        ctx.bus.publish(.bombExploded(position: bomb.position))
        if ctx.world.mode == .rush, let name = bomb.site?.name {
            ctx.bus.publish(.announcement(text: "Station \(name) destroyed!"))
        }
    }
}

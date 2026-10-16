import CoreGraphics

/// The bomb: follows its carrier, drops where the carrier dies, gets picked up by attackers,
/// is planted by holding E inside a site, ticks for 45 s and is defused by a defender holding E next to it.
/// Planting or defusing roots the soldier in place.
@MainActor
final class BombSystem {
    unowned let ctx: BattleContext
    private let damage: DamageSystem

    init(ctx: BattleContext, damage: DamageSystem) {
        self.ctx = ctx
        self.damage = damage
    }

    func update(dt: CGFloat) {
        let bomb = ctx.world.bomb
        switch bomb.state {
        case .carried(let id):
            updateCarried(bomb, carrierId: id, dt: dt)
        case .dropped:
            pickUp(bomb)
        case .planted:
            updatePlanted(bomb, dt: dt)
        case .defused, .exploded:
            break
        }
    }

    /// The site the soldier stands in, if any.
    func site(at point: CGPoint) -> BombSite? {
        ctx.world.sites.first { $0.contains(point) }
    }

    private func updateCarried(_ bomb: Bomb, carrierId: Int, dt: CGFloat) {
        guard let carrier = ctx.world.soldier(carrierId), carrier.isAlive else {
            bomb.state = .dropped
            bomb.plantProgress = 0
            ctx.bus.publish(.bombDropped(position: bomb.position))
            return
        }
        bomb.position = carrier.position
        guard carrier.wantsToInteract, let site = site(at: carrier.position) else {
            bomb.plantProgress = 0
            return
        }
        root(carrier)
        bomb.plantProgress += dt / BombConfig.plantTime
        guard bomb.plantProgress >= 1 else { return }
        bomb.state = .planted
        bomb.site = site
        bomb.fuseLeft = BombConfig.fuseTime
        bomb.plantProgress = 0
        carrier.wantsToInteract = false
        ctx.bus.publish(.bombPlanted(site: site.name, planterId: carrier.id))
        ctx.bus.publish(.announcement(text: "Bomb planted on site \(site.name)!"))
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
        bomb.state = .defused
        defuser.wantsToInteract = false
        ctx.bus.publish(.bombDefused(defuserId: defuser.id))
        ctx.bus.publish(.announcement(text: "Bomb defused!"))
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
    }
}

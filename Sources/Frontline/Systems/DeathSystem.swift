import CoreGraphics

/// Handles deaths (removal, wreck explosions) and hero respawns.
@MainActor
final class DeathSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
        ctx.bus.subscribe { [unowned self] event in
            if case .killed(let victimId, _) = event { self.handleDeath(victimId) }
        }
    }

    private func handleDeath(_ victimId: Int) {
        guard let victim = ctx.world.entity(victimId) else { return }
        victim.status.clear()
        victim.targetId = nil
        victim.moveDir = .zero
        if let hero = victim as? Hero {
            hero.respawnTimer = hero.respawnDuration
            hero.recallTimer = nil
        } else {
            victim.isRemoved = true
        }
        if victim.isArmored {
            let big = victim.kind.isStructure || victim.radius >= 30
            ctx.bus.publish(.explosion(position: victim.position, radius: victim.radius * 1.6, big: big))
        }
    }

    func update(dt: CGFloat) {
        for hero in ctx.world.heroes where !hero.isAlive {
            hero.respawnTimer -= dt
            if hero.respawnTimer <= 0 { respawn(hero) }
        }
    }

    private func respawn(_ hero: Hero) {
        hero.respawnTimer = 0
        hero.hp = hero.maxHp
        hero.position = hero.spawnPoint
        hero.ammo = hero.stats.magSize
        hero.reloadTimer = 0
        hero.targetId = nil
        hero.status.clear()
        hero.recentHeroAttackers.removeAll()
        ctx.bus.publish(.heroRespawned(heroId: hero.id))
    }
}

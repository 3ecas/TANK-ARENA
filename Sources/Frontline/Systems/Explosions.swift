import CoreGraphics

/// Area damage for rockets, tank shells and wrecks: soldiers in line of sight of the blast take damage that
/// falls off with distance; vehicles in reach take `vehicleDamage`.
@MainActor
enum Explosions {
    static func blast(at point: CGPoint, radius: CGFloat, damage amount: CGFloat, vehicleDamage: CGFloat,
                      attacker: Soldier?, weaponName: String, ctx: BattleContext, damage: DamageSystem) {
        let world = ctx.world
        for soldier in world.soldiers where soldier.isAlive && !soldier.isMounted {
            let distance = soldier.position.distance(to: point)
            guard distance <= radius, world.map.hasLineOfSight(point, soldier.position) else { continue }
            damage.apply(amount * (1 - 0.6 * distance / radius), to: soldier, from: attacker, weaponName: weaponName)
        }
        if vehicleDamage > 0 {
            for vehicle in world.vehicles where vehicle.isAlive {
                let reach = radius + vehicle.radius
                let distance = vehicle.position.distance(to: point)
                guard distance <= reach else { continue }
                damage.apply(vehicleDamage * (1 - 0.5 * distance / reach), to: vehicle, from: attacker)
            }
        }
        ctx.bus.publish(.grenadeExploded(type: .frag, position: point, radius: radius))
    }
}

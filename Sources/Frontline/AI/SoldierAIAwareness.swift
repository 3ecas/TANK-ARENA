import CoreGraphics

/// Where a bot looks when it is not shooting: the doorway its squad is stacked on, the predicted position of
/// enemies its team has seen, or the openings around it (favouring the enemy side), switching every few seconds.
/// While walking it glances at doorways it passes instead of staring straight ahead.
extension SoldierAI {
    func watchPoint(squad: Squad?) -> CGPoint? {
        if let squad = squad, let door = squad.stackDoor, let point = squad.stackPoint {
            let intoRoom = (door.position - point).normalized
            return door.position + intoRoom * 150
        }
        let world = ctx.world
        let openings = services.chokepoints.visible(from: soldier.position, within: AIConfig.watchRange, map: world.map)
        if let enemy = services.intel.predictions(for: soldier.team, world: world).first {
            if world.map.hasLineOfSight(soldier.position, enemy) { return enemy }
            // Can't see where the enemy should be: cover the opening it would come through.
            if let door = openings.min(by: { $0.position.distance(to: enemy) < $1.position.distance(to: enemy) }) {
                return door.position
            }
            return enemy
        }
        guard !openings.isEmpty else { return nil }
        let enemySpawn = world.spawnZone(soldier.team.opponent)
        let enemyDirection = (CGPoint(x: enemySpawn.midX, y: enemySpawn.midY) - soldier.position).normalized
        let ranked = openings.sorted { watchScore($0, enemyDirection) < watchScore($1, enemyDirection) }
        let top = Array(ranked.prefix(3))
        let index = (soldier.id + Int(world.time / AIConfig.watchSwitchTime)) % top.count
        return top[index].position
    }

    /// Lower is better: nearby openings that face the enemy side.
    private func watchScore(_ door: Chokepoint, _ enemyDirection: CGPoint) -> CGFloat {
        let offset = door.position - soldier.position
        let facing = offset.normalized.dot(enemyDirection)
        return offset.length - facing * 250
    }

    /// A doorway close by and not behind the bot, to check while walking past.
    func glancePoint() -> CGPoint? {
        let direction = soldier.moveDir
        guard direction.lengthSquared > 0.01 else { return nil }
        let heading = direction.normalized
        return services.chokepoints.visible(from: soldier.position, within: AIConfig.glanceRange, map: ctx.world.map)
            .filter { ($0.position - soldier.position).normalized.dot(heading) > -0.2 && $0.position.distance(to: soldier.position) > 40 }
            .min { $0.position.distance(to: soldier.position) < $1.position.distance(to: soldier.position) }?
            .position
    }

    /// Where the last seen enemy probably is now (its last position moved on along its last velocity).
    func predictedThreat(_ threat: CGPoint) -> CGPoint {
        let age = Swift.min(ctx.world.time - threatTime, AIConfig.predictionHorizon)
        return threat + threatVelocity * age
    }
}

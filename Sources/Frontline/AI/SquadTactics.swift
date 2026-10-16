import CoreGraphics

/// Team tactics on top of the squads, so bots push together instead of trickling in one by one:
/// - attackers gather at a staging point before their target site, then execute together, opening with grenades;
/// - defenders retaking an armed bomb or station gather first too, then retake together.
extension SquadCoordinator {
    func updateTactics() {
        let world = ctx.world
        plan(attackPlan, team: world.attackers, target: attackGoal(), from: spawnCenter(world.attackers),
             timeout: AIConfig.gatherTimeout)
        plan(retakePlan, team: world.defenders, target: retakeGoal(), from: teamCentroid(world.defenders),
             timeout: AIConfig.retakeGatherTimeout)
    }

    /// The site the attacking team pushes as one: bomb mode — its chosen site until the plant; rush — the first
    /// station still standing and unarmed. Nil while a bomb is armed (squads guard it instead).
    private func attackGoal() -> BombSite? {
        let world = ctx.world
        if world.anyPlanted { return nil }
        switch world.mode {
        case .bomb: return attackTarget
        case .rush: return world.bombs.first { $0.isIdle }?.site
        }
    }

    /// The armed site the defenders must retake, if any.
    private func retakeGoal() -> BombSite? {
        ctx.world.bombs.first { $0.isPlanted }?.site
    }

    private func plan(_ plan: TeamPlan, team: Team, target: BombSite?, from origin: CGPoint?, timeout: CGFloat) {
        let world = ctx.world
        let now = world.time
        let teamSquads = squads.filter { $0.team == team }
        if target !== plan.target {
            var stage: CGPoint?
            if let target = target, let origin = origin {
                stage = TeamPlan.stagingPoint(from: origin, to: target.center, distance: AIConfig.stageDistance, nav: world.nav)
            }
            plan.reset(target: target, stage: stage, now: now)
            for squad in teamSquads { squad.stagePoint = plan.phase == .gather ? stage : nil }
        }
        guard plan.phase == .gather, let stage = plan.stage, let target = plan.target else { return }
        let bots = teamSquads.flatMap { $0.alive }
        let arrived = bots.filter { $0.soldier.position.distance(to: stage) < AIConfig.stageRadius }.count
        let ready = !bots.isEmpty && CGFloat(arrived) >= CGFloat(bots.count) * AIConfig.gatherFraction
        let urgent = (team == world.attackers && world.mode == .bomb && world.roundTimeLeft < AIConfig.rushTimeLeft + 15)
            || (team == world.defenders && (world.bombs.first { $0.isPlanted }?.fuseLeft ?? 99) < AIConfig.retakeHurry)
        if ready || urgent || now - plan.since > timeout {
            plan.execute(now: now)
            for squad in teamSquads { squad.stagePoint = nil }
            openWithUtility(bots, at: target)
        }
    }

    /// Going in: bots in throwing range lob their grenades onto the site first.
    private func openWithUtility(_ bots: [SoldierAI], at site: BombSite) {
        for bot in bots where bot.soldier.grenade != nil && !bot.soldier.isPlayer {
            let distance = bot.soldier.position.distance(to: site.center)
            guard distance <= GrenadeConfig.maxThrowDistance, CGFloat.random(in: 0...1) < AIConfig.executeUtilityChance else { continue }
            let spread = CGPoint(x: CGFloat.random(in: -90...90), y: CGFloat.random(in: -90...90))
            services.grenades.throwGrenade(bot.soldier, at: site.center + spread)
        }
    }

    private func spawnCenter(_ team: Team) -> CGPoint? {
        let rect = ctx.world.spawnZone(team)
        return CGPoint(x: rect.midX, y: rect.midY)
    }

    private func teamCentroid(_ team: Team) -> CGPoint? {
        let living = ctx.world.soldiers.filter { $0.isAlive && $0.team == team }
        guard !living.isEmpty else { return nil }
        return living.reduce(CGPoint.zero) { $0 + $1.position } / CGFloat(living.count)
    }

    /// True while the team is still gathering for a push (room clearing then is skipped: no stacking).
    func isExecuting(_ team: Team) -> Bool {
        let plan = team == ctx.world.attackers ? attackPlan : retakePlan
        return plan.target != nil && plan.phase == .execute && ctx.world.time - plan.since < AIConfig.executeRushTime
    }
}

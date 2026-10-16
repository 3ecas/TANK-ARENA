import CoreGraphics

/// Team tactics on top of the squads, so bots push together instead of trickling in one by one:
/// - attackers gather at a staging point before their target site, then execute together, opening with grenades;
/// - defenders retaking an armed bomb or station gather first too, then retake together.
extension SquadCoordinator {
    func updateTactics() {
        let world = ctx.world
        checkWave()
        plan(attackPlan, team: world.attackers, target: attackGoal(),
             from: teamCentroid(world.attackers) ?? spawnCenter(world.attackers),
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
        case .rush:
            let idle = world.bombs.filter { $0.isIdle }.compactMap { $0.site }
            // Keep pushing the current station while it stands; otherwise pick the one the fewest defenders were seen at.
            if let current = attackPlan.target, idle.contains(where: { $0 === current }) { return current }
            let sightings = services.intel.predictions(for: world.attackers, world: world)
            return idle.min { defenders(near: $0, sightings) < defenders(near: $1, sightings) }
        }
    }

    private func defenders(near site: BombSite, _ sightings: [CGPoint]) -> Int {
        sightings.filter { $0.distance(to: site.center) < 600 }.count
    }

    /// Rush: a push that has run out of people is called off, so the respawned attackers regroup and
    /// go again together as a new wave instead of trickling in.
    private func checkWave() {
        let world = ctx.world
        guard world.mode == .rush, !world.anyPlanted, attackPlan.phase == .execute,
              let target = attackPlan.target, world.time - attackPlan.since > AIConfig.waveTimeout else { return }
        let near = world.soldiers.filter {
            $0.isAlive && $0.team == world.attackers && $0.position.distance(to: target.center) < 650
        }.count
        if near < AIConfig.waveMinimum {
            attackPlan.reset(target: nil, stage: nil, now: world.time)
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
            for squad in teamSquads {
                squad.stagePoint = plan.phase == .gather ? stage : nil
                // Gathering with the team replaces any flank route.
                if squad.stagePoint != nil { squad.flankPoint = nil }
            }
            objectiveTimer = 0
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

    /// True during the first seconds after the team goes in (squads then push through doors without stacking).
    func isExecuting(_ team: Team) -> Bool {
        let plan = team == ctx.world.attackers ? attackPlan : retakePlan
        return plan.target != nil && plan.phase == .execute && ctx.world.time - plan.since < AIConfig.executeRushTime
    }
}

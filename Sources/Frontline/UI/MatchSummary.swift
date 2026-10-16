/// One-line reason the round ended, for the game-over screen.
@MainActor
enum MatchSummary {
    static func reason(_ world: BattleWorld) -> String {
        if world.mode == .rush {
            if world.bombs.allSatisfy({ $0.isExploded }) { return "Both stations destroyed" }
            return "The attackers ran out of tickets"
        }
        switch world.bomb.state {
        case .exploded: return "The bomb exploded"
        case .defused: return "The bomb was defused"
        default: break
        }
        if world.aliveCount(world.defenders) == 0 { return "All defenders eliminated" }
        if world.aliveCount(world.attackers) == 0 { return "All attackers eliminated" }
        return "Time ran out"
    }
}

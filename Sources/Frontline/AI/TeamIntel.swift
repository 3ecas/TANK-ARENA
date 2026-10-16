import CoreGraphics

/// What each team knows about enemy positions: every sighting by a bot is shared with the whole team,
/// and positions are extrapolated a little from the enemy's last movement to predict where it is now.
@MainActor
final class TeamIntel {
    private struct Sighting {
        let position: CGPoint
        let velocity: CGPoint
        let time: CGFloat
    }

    private var sightings: [Team: [Int: Sighting]] = [:]

    func report(by team: Team, enemy: Soldier, time: CGFloat) {
        sightings[team, default: [:]][enemy.id] = Sighting(position: enemy.position, velocity: enemy.velocity, time: time)
    }

    /// Predicted current positions of recently seen enemies that are still alive (the newest sighting first).
    func predictions(for team: Team, world: BattleWorld) -> [CGPoint] {
        let now = world.time
        return (sightings[team] ?? [:])
            .filter { now - $0.value.time < AIConfig.intelMemory && world.soldier($0.key)?.isAlive == true }
            .map { $0.value }
            .sorted { $0.time > $1.time }
            .map { $0.position + $0.velocity * Swift.min(now - $0.time, AIConfig.predictionHorizon) }
    }
}

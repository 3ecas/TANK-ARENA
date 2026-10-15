import CoreGraphics

enum HeroAIStateKind {
    case dead, shopping, laning, trading, retreating, recalling, ganking, objective

    var displayName: String {
        switch self {
        case .dead: return "Dead"
        case .shopping: return "Shopping"
        case .laning: return "Laning"
        case .trading: return "Trading"
        case .retreating: return "Retreating"
        case .recalling: return "Recalling"
        case .ganking: return "Ganking"
        case .objective: return "Objective"
        }
    }
}

/// One state of the hero AI state machine.
@MainActor
protocol HeroAIState: AnyObject {
    func enter(_ ai: HeroAIController)
    /// Runs on every think step; returns the next state, or nil to stay.
    func think(_ ai: HeroAIController) -> HeroAIStateKind?
}

/// Waiting to respawn.
@MainActor
final class DeadState: HeroAIState {
    func enter(_ ai: HeroAIController) {
        ai.moveGoal = nil
    }

    func think(_ ai: HeroAIController) -> HeroAIStateKind? { nil }
}

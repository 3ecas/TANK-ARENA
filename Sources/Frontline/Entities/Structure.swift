import CoreGraphics

enum StructureRole {
    /// tier 1 = outer bunker, tier 2 = inner bunker.
    case bunker(tier: Int)
    case barracks
    case hq
}

/// Bunkers, barracks and HQs.
final class Structure: Entity {
    let role: StructureRole
    let lane: Lane?

    init(id: Int, kind: EntityKind, team: Team, position: CGPoint, role: StructureRole, lane: Lane?) {
        self.role = role
        self.lane = lane
        super.init(id: id, kind: kind, team: team, position: position, stats: UnitCatalog.stats(for: kind))
    }

    var bunkerTier: Int? {
        if case .bunker(let tier) = role { return tier }
        return nil
    }

    var isBarracks: Bool {
        if case .barracks = role { return true }
        return false
    }

    var isHQ: Bool {
        if case .hq = role { return true }
        return false
    }

    var title: String {
        let laneName = lane.map { "\($0.displayName) " } ?? ""
        switch role {
        case .bunker(let tier): return "\(laneName)\(tier == 1 ? "outer" : "inner") bunker"
        case .barracks: return "\(laneName)barracks"
        case .hq: return "HQ"
        }
    }
}

enum EntityKind {
    case hero
    case rifleman, rocketSoldier, tank, apc, superTank
    case bunker, barracks, hq
    case sentry, squadSoldier, summonTank, helicopter
    case mercenary, heavyMercenary, depotGuardian

    var isStructure: Bool {
        switch self {
        case .bunker, .barracks, .hq: return true
        default: return false
        }
    }

    /// Lane troops spawned by waves.
    var isTroop: Bool {
        switch self {
        case .rifleman, .rocketSoldier, .tank, .apc, .superTank: return true
        default: return false
        }
    }

    var isVehicle: Bool {
        switch self {
        case .tank, .apc, .superTank, .summonTank, .depotGuardian: return true
        default: return false
        }
    }

    var isInfantry: Bool {
        switch self {
        case .hero, .rifleman, .rocketSoldier, .squadSoldier, .mercenary, .heavyMercenary: return true
        default: return false
        }
    }

    var isNeutralMonster: Bool {
        switch self {
        case .mercenary, .heavyMercenary, .depotGuardian: return true
        default: return false
        }
    }

    /// Units that EMP disables completely.
    var isMechanical: Bool {
        isVehicle || self == .sentry || self == .helicopter || self == .bunker || self == .hq
    }

    var displayName: String {
        switch self {
        case .hero: return "Soldier"
        case .rifleman: return "Rifleman"
        case .rocketSoldier: return "Rocket Soldier"
        case .tank: return "Tank"
        case .apc: return "APC"
        case .superTank: return "Super Tank"
        case .bunker: return "Bunker"
        case .barracks: return "Barracks"
        case .hq: return "HQ"
        case .sentry: return "Sentry"
        case .squadSoldier: return "Squad Soldier"
        case .summonTank: return "Tank"
        case .helicopter: return "Helicopter"
        case .mercenary: return "Mercenary"
        case .heavyMercenary: return "Heavy Mercenary"
        case .depotGuardian: return "Depot Guardian"
        }
    }
}

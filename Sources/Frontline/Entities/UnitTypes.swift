import CoreGraphics

/// Foot soldiers: riflemen, rocket soldiers, squads, mercenaries.
final class Infantry: Entity {}

/// Ground vehicles with an independently rotating turret.
final class Vehicle: Entity {
    /// Riflemen deployed when this vehicle is destroyed (APCs).
    var deploysOnDeath = 0
}

/// Flying units (helicopters). Rendered with a ground shadow.
final class Aircraft: Entity {
    var altitude: CGFloat = SummonConfig.helicopterAltitude
}

/// Stationary automated guns (sentry turrets).
final class Turret: Entity {}

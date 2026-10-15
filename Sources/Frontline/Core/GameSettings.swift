/// Options chosen in the main menu.
struct GameSettings {
    var difficulty: Difficulty = .normal
    var loadoutIndex: Int = 0

    var startingLoadout: StartingLoadout {
        StartingLoadouts.all[min(max(loadoutIndex, 0), StartingLoadouts.all.count - 1)]
    }
}

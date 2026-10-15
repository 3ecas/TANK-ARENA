import CoreGraphics

/// League-style controls turned into hero intent:
/// right-click ground = move (hold to keep steering), right-click enemy = attack (chase into range),
/// Q/W/E/R = abilities (instant, or hold to aim and release to cast), F = roll, S = stop,
/// B = recall, 1-4 = spend ability points. Idle soldiers auto-attack enemies in range.
@MainActor
final class PlayerController {
    let hero: Hero
    unowned let ctx: GameContext
    /// Slot currently being aimed (key held).
    private(set) var aimingSlot: Int?
    /// Called with short feedback messages ("Ability on cooldown"...).
    var onMessage: ((String) -> Void)?
    /// Called when the player issues a move order (for the click marker).
    var onMoveOrder: ((CGPoint) -> Void)?

    private let abilityKeys: [UInt16] = [KeyCode.q, KeyCode.w, KeyCode.e, KeyCode.r]
    private let pointKeys: [UInt16] = [KeyCode.one, KeyCode.two, KeyCode.three, KeyCode.four]

    init(hero: Hero, ctx: GameContext) {
        self.hero = hero
        self.ctx = ctx
    }

    func cancelAiming() { aimingSlot = nil }

    /// - Parameter leftClickAvailable: false when the UI consumed the left click this frame.
    func update(input: InputManager, mouseWorld: CGPoint, leftClickAvailable: Bool) {
        guard hero.isAlive else {
            aimingSlot = nil
            return
        }
        hero.aimPoint = mouseWorld
        handleRightMouse(input: input, mouseWorld: mouseWorld)
        handleKeys(input: input, mouseWorld: mouseWorld)
        handleAbilities(input: input, mouseWorld: mouseWorld, leftClickAvailable: leftClickAvailable)
        autoAcquireTarget()
    }

    // MARK: Movement & attack orders

    private func handleRightMouse(input: InputManager, mouseWorld: CGPoint) {
        if input.rightPressed {
            if aimingSlot != nil {
                aimingSlot = nil      // right-click cancels an aimed ability
                return
            }
            if let enemy = ctx.targeting.enemyClosest(to: mouseWorld, radius: GameConfig.attackClickRadius,
                                                      viewer: hero) {
                hero.targetId = enemy.id
                hero.chasesTarget = true
                hero.moveGoal = nil
            } else {
                moveOrder(to: mouseWorld)
                onMoveOrder?(hero.moveGoal ?? mouseWorld)
            }
        } else if input.rightDown && !hero.chasesTarget && aimingSlot == nil {
            moveOrder(to: mouseWorld)     // holding right mouse keeps steering
        }
    }

    private func moveOrder(to point: CGPoint) {
        hero.targetId = nil
        hero.chasesTarget = false
        hero.moveGoal = ctx.world.nav.nearestWalkable(point.clamped(to: ctx.world.map.bounds.insetBy(dx: 30, dy: 30)))
    }

    private func handleKeys(input: InputManager, mouseWorld: CGPoint) {
        if input.wasPressed(KeyCode.s) {
            hero.moveGoal = nil
            hero.targetId = nil
            hero.chasesTarget = false
        }
        if input.wasPressed(KeyCode.f) && !DodgeRoll.perform(hero, toward: mouseWorld) {
            onMessage?("Roll on cooldown")
        }
        if input.wasPressed(KeyCode.b) {
            if ctx.recall.begin(hero) {
                hero.moveGoal = nil
                hero.chasesTarget = false
            } else if !hero.isRecalling {
                onMessage?("Can't recall here")
            }
        }
        for (slot, key) in pointKeys.enumerated() where input.wasPressed(key) {
            if !LoadoutManager.spendPoint(onSlot: slot, hero: hero) && hero.abilityPoints > 0 {
                onMessage?("Can't rank up that ability")
            }
        }
    }

    /// Standing still with nothing to do: shoot the nearest enemy in range (like League's idle attack).
    private func autoAcquireTarget() {
        guard hero.targetId == nil, hero.moveGoal == nil, !hero.isRecalling, !hero.status.isDashing else { return }
        if let enemy = ctx.targeting.nearestTarget(for: hero, within: hero.stats.range, includeNeutral: false,
                                                  preferNonHeroes: false) {
            hero.targetId = enemy.id
            hero.chasesTarget = false
        }
    }

    // MARK: Abilities

    private func handleAbilities(input: InputManager, mouseWorld: CGPoint, leftClickAvailable: Bool) {
        for (slot, key) in abilityKeys.enumerated() {
            if input.wasPressed(key) { begin(slot: slot, mouseWorld: mouseWorld) }
            if input.wasReleased(key) && aimingSlot == slot {
                aimingSlot = nil
                cast(slot: slot, at: mouseWorld)
            }
        }
        // Left click while aiming casts immediately.
        if let slot = aimingSlot, input.leftPressed && leftClickAvailable {
            aimingSlot = nil
            cast(slot: slot, at: mouseWorld)
        }
    }

    private func begin(slot: Int, mouseWorld: CGPoint) {
        guard let id = hero.loadout.ability(inSlot: slot) else {
            onMessage?("No ability in \(Loadout.slotLabels[slot]) - buy one in the shop (P at base)")
            return
        }
        let readiness = ctx.abilities.readiness(hero, slot: slot)
        guard readiness == .success else {
            if let message = readiness.message { onMessage?(message) }
            return
        }
        if AbilityCatalog.def(id).castMode.isInstant {
            cast(slot: slot, at: mouseWorld)
        } else {
            aimingSlot = slot
        }
    }

    private func cast(slot: Int, at point: CGPoint) {
        let result = ctx.abilities.tryCast(hero, slot: slot, target: point)
        if let message = result.message { onMessage?(message) }
    }
}

import CoreGraphics

/// Turns player input into hero intent: movement, aim, auto-attack target lock,
/// ability casting (instant or hold-to-aim), recall and ability point spending.
@MainActor
final class PlayerController {
    let hero: Hero
    unowned let ctx: GameContext
    /// Slot currently being aimed (button / key held).
    private(set) var aimingSlot: Int?
    /// Called with short feedback messages ("Ability on cooldown"...).
    var onMessage: ((String) -> Void)?

    private let abilityKeys: [UInt16?] = [nil, KeyCode.q, KeyCode.e, KeyCode.r]
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
            hero.moveDir = .zero
            return
        }
        hero.aimPoint = mouseWorld
        hero.moveDir = movementVector(input)
        updateTargetLock(input: input, mouseWorld: mouseWorld)

        if input.wasPressed(KeyCode.b) && !ctx.recall.begin(hero) && !hero.isRecalling {
            onMessage?("Can't recall here")
        }
        for (slot, key) in pointKeys.enumerated() where input.wasPressed(key) {
            if !LoadoutManager.spendPoint(onSlot: slot, hero: hero) && hero.abilityPoints > 0 {
                onMessage?("Can't rank up that ability")
            }
        }
        handleAbilities(input: input, mouseWorld: mouseWorld, leftClickAvailable: leftClickAvailable)
    }

    private func movementVector(_ input: InputManager) -> CGPoint {
        var v = CGPoint.zero
        if input.isDown(KeyCode.w) || input.isDown(KeyCode.up) { v.y += 1 }
        if input.isDown(KeyCode.s) || input.isDown(KeyCode.down) { v.y -= 1 }
        if input.isDown(KeyCode.a) || input.isDown(KeyCode.left) { v.x -= 1 }
        if input.isDown(KeyCode.d) || input.isDown(KeyCode.right) { v.x += 1 }
        return v.normalized
    }

    private func updateTargetLock(input: InputManager, mouseWorld: CGPoint) {
        let snapped = ctx.targeting.enemyClosest(to: mouseWorld, radius: GameConfig.targetSnapRadius, viewer: hero)
        if input.rightPressed {
            hero.targetId = snapped?.id      // empty ground clears the lock
        } else if input.rightDown, let snapped = snapped {
            hero.targetId = snapped.id       // holding: follow the enemy nearest the cursor
        }
    }

    private func handleAbilities(input: InputManager, mouseWorld: CGPoint, leftClickAvailable: Bool) {
        for slot in 0..<Loadout.slotCount {
            let pressed: Bool
            let released: Bool
            if let key = abilityKeys[slot] {
                pressed = input.wasPressed(key)
                released = input.wasReleased(key)
            } else {
                pressed = input.leftPressed && leftClickAvailable
                released = input.leftReleased
            }
            if pressed { begin(slot: slot, mouseWorld: mouseWorld) }
            if released && aimingSlot == slot {
                aimingSlot = nil
                cast(slot: slot, at: mouseWorld)
            }
        }
    }

    private func begin(slot: Int, mouseWorld: CGPoint) {
        guard let id = hero.loadout.ability(inSlot: slot) else { return }
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

import CoreGraphics

/// Top-down shooter controls: WASD to move, mouse to aim, left mouse to shoot,
/// R reload, 1 / 2 / Q weapons, G grenade, F knife, hold E to plant / defuse the bomb.
@MainActor
final class PlayerController {
    let soldier: Soldier
    private let weapons: WeaponSystem
    private let grenades: GrenadeSystem
    private let melee: MeleeSystem
    /// Called with short feedback messages ("No grenade left"...).
    var onMessage: ((String) -> Void)?

    init(soldier: Soldier, weapons: WeaponSystem, grenades: GrenadeSystem, melee: MeleeSystem) {
        self.soldier = soldier
        self.weapons = weapons
        self.grenades = grenades
        self.melee = melee
    }

    /// - Parameter leftClickAvailable: false when the UI consumed the click this frame.
    func update(input: InputManager, mouseWorld: CGPoint, leftClickAvailable: Bool) {
        guard soldier.isAlive else {
            soldier.moveDir = .zero
            soldier.wantsToFire = false
            soldier.wantsToInteract = false
            return
        }
        soldier.aimPoint = mouseWorld
        soldier.moveDir = movement(input)
        soldier.wantsToFire = input.leftDown && leftClickAvailable
        if input.leftPressed && leftClickAvailable { soldier.firePressed = true }
        soldier.wantsToInteract = input.isDown(KeyCode.e)

        if input.wasPressed(KeyCode.r) { weapons.reload(soldier) }
        if input.wasPressed(KeyCode.one) { weapons.switchTo(soldier, index: 0) }
        if input.wasPressed(KeyCode.two) { weapons.switchTo(soldier, index: 1) }
        if input.wasPressed(KeyCode.q) { weapons.switchTo(soldier, index: soldier.activeIndex == 0 ? 1 : 0) }
        if input.wasPressed(KeyCode.f) { melee.swing(soldier) }
        if input.wasPressed(KeyCode.g) && !grenades.throwGrenade(soldier, at: mouseWorld) {
            onMessage?("No grenade left")
        }
    }

    private func movement(_ input: InputManager) -> CGPoint {
        var v = CGPoint.zero
        if input.isDown(KeyCode.w) || input.isDown(KeyCode.up) { v.y += 1 }
        if input.isDown(KeyCode.s) || input.isDown(KeyCode.down) { v.y -= 1 }
        if input.isDown(KeyCode.a) || input.isDown(KeyCode.left) { v.x -= 1 }
        if input.isDown(KeyCode.d) || input.isDown(KeyCode.right) { v.x += 1 }
        return v.normalized
    }
}

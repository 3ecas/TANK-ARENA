import CoreGraphics

/// A carried weapon: its definition plus magazine, reserve, reload and fire cooldown.
struct WeaponState {
    let def: WeaponDef
    var magazine: Int
    /// Spare rounds (nil = unlimited).
    var reserve: Int?
    var reloadTimer: CGFloat = 0
    var cooldown: CGFloat = 0

    init(_ id: WeaponID) {
        def = WeaponCatalog.def(id)
        magazine = def.magSize
        reserve = def.reserveAmmo
    }

    var isReloading: Bool { reloadTimer > 0 }
    var hasSpareAmmo: Bool { reserve.map { $0 > 0 } ?? true }
    var isEmpty: Bool { magazine <= 0 && !hasSpareAmmo }
    var magazineFraction: CGFloat { CGFloat(magazine) / CGFloat(Swift.max(def.magSize, 1)) }

    /// Moves rounds from the reserve into the magazine.
    mutating func finishReload() {
        reloadTimer = 0
        let needed = def.magSize - magazine
        guard needed > 0 else { return }
        if let spare = reserve {
            let taken = Swift.min(needed, spare)
            magazine += taken
            reserve = spare - taken
        } else {
            magazine = def.magSize
        }
    }
}

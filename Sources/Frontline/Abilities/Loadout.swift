import CoreGraphics

/// Owned abilities (with ranks), the 4 equipped slots and cooldowns.
struct Loadout {
    static let slotCount = 4
    static let slotLabels = ["Q", "W", "E", "R"]

    private(set) var slots: [AbilityID?] = [nil, nil, nil, nil]
    private(set) var ranks: [AbilityID: Int] = [:]
    private var cooldowns: [AbilityID: CGFloat] = [:]

    var owned: [AbilityID] { AbilityID.allCases.filter { ranks[$0] != nil } }
    var firstEmptySlot: Int? { slots.firstIndex(where: { $0 == nil }) }

    func ability(inSlot slot: Int) -> AbilityID? {
        guard slots.indices.contains(slot) else { return nil }
        return slots[slot]
    }

    func slot(of id: AbilityID) -> Int? { slots.firstIndex(where: { $0 == id }) }
    func rank(of id: AbilityID) -> Int { ranks[id] ?? 0 }
    func owns(_ id: AbilityID) -> Bool { ranks[id] != nil }
    func cooldown(of id: AbilityID) -> CGFloat { cooldowns[id] ?? 0 }

    mutating func learn(_ id: AbilityID) {
        if ranks[id] == nil { ranks[id] = 1 }
    }

    /// Raises the rank by one. Returns false at max rank or when not owned.
    mutating func rankUp(_ id: AbilityID) -> Bool {
        guard let rank = ranks[id], rank < AbilityDef.maxRank else { return false }
        ranks[id] = rank + 1
        return true
    }

    /// Puts `id` into `slot`, swapping with the slot it previously occupied.
    mutating func equip(_ id: AbilityID, slot: Int) {
        guard slots.indices.contains(slot), owns(id) else { return }
        if let previous = self.slot(of: id) {
            slots[previous] = slots[slot]
        }
        slots[slot] = id
    }

    mutating func setCooldown(_ id: AbilityID, _ value: CGFloat) {
        cooldowns[id] = value
    }

    mutating func tick(_ dt: CGFloat) {
        for (id, value) in cooldowns where value > 0 {
            cooldowns[id] = Swift.max(0, value - dt)
        }
    }
}

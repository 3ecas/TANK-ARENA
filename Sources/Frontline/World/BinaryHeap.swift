/// Minimal min-heap of (priority, value) used by the A* pathfinder.
struct BinaryHeap {
    private var items: [(priority: Float, value: Int32)] = []

    var isEmpty: Bool { items.isEmpty }

    mutating func push(_ priority: Float, _ value: Int32) {
        items.append((priority, value))
        var child = items.count - 1
        while child > 0 {
            let parent = (child - 1) / 2
            if items[parent].priority <= items[child].priority { break }
            items.swapAt(parent, child)
            child = parent
        }
    }

    mutating func pop() -> Int32? {
        guard !items.isEmpty else { return nil }
        let top = items[0].value
        let last = items.removeLast()
        if !items.isEmpty {
            items[0] = last
            var parent = 0
            while true {
                let left = parent * 2 + 1, right = left + 1
                var smallest = parent
                if left < items.count && items[left].priority < items[smallest].priority { smallest = left }
                if right < items.count && items[right].priority < items[smallest].priority { smallest = right }
                if smallest == parent { break }
                items.swapAt(parent, smallest)
                parent = smallest
            }
        }
        return top
    }
}

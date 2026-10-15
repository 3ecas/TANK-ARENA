/// Outcome of a shop / loadout action, with a message for the UI.
enum ShopResult {
    case success(String)
    case failure(String)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var message: String {
        switch self {
        case .success(let text), .failure(let text): return text
        }
    }
}

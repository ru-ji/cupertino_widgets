import Foundation

/// A single toolbar button that reports taps back to Dart via `actionId`.
struct BarItemConfig: Codable, Hashable {
    let title: String?
    let icon: IconConfig?
    let actionId: String
}

/// One leading/trailing entry: `type == "item"` is a single button (fields
/// inline); `type == "group"` is several buttons sharing one glass capsule
/// (`items`). Separate entries render as separate capsules on iOS 26.
struct BarEntryConfig: Codable, Hashable {
    let type: String
    let title: String?
    let icon: IconConfig?
    let actionId: String?
    let items: [BarItemConfig]?

    var asItem: BarItemConfig? {
        guard type == "item", let actionId = actionId else { return nil }
        return BarItemConfig(title: title, icon: icon, actionId: actionId)
    }

    var groupItems: [BarItemConfig] {
        if type == "group" { return items ?? [] }
        if let item = asItem { return [item] }
        return []
    }
}

/// Navigation-bar configuration shared by the standalone app bar and every
/// page of the native scaffold.
struct AppBarConfig: Codable, Hashable {
    let title: String
    let displayMode: String?  // "inline" | "large"
    let leading: [BarEntryConfig]?
    let trailing: [BarEntryConfig]?
}

import Foundation

/// One row of a native `List`/`Form` section. `type` selects the row rendering:
/// "label" (icon + title/subtitle + optional trailing value/chevron),
/// "toggle" (trailing switch), or "button" (tinted, tappable).
struct ListRowConfig: Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: IconConfig?
    let value: String?
    let showChevron: Bool?
    let type: String?  // "label" | "toggle" | "button"
    let toggleValue: Bool?
    let enabled: Bool?
}

/// A `Section` of a native `List`/`Form`: optional header/footer + rows.
struct ListSectionConfig: Codable, Hashable {
    let header: String?
    let footer: String?
    let rows: [ListRowConfig]
}

/// Creation/update parameters for the native list/form platform view.
struct ListConfig: Codable, Hashable {
    let variant: String?  // "list" | "form"
    let style: String?    // "automatic" | "plain" | "grouped" | "insetGrouped" | "sidebar"
    let scrollable: Bool?
    let isDark: Bool?
    let cornerRadius: Double?  // inset-grouped card radius; nil = default (10)
    let tint: Int?        // ARGB accent color
    let sections: [ListSectionConfig]
}

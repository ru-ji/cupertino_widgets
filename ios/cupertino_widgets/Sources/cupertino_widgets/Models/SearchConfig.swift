import Foundation

/// Configuration for a scaffold page's native SwiftUI `.searchable` field.
/// Attached to an `AppBarConfig`; when present the page becomes searchable.
struct SearchConfig: Codable, Hashable {
    let placeholder: String?
    // "automatic" | "toolbar" | "navigationBarDrawer" | "navigationBarDrawerAlways"
    let placement: String?
}

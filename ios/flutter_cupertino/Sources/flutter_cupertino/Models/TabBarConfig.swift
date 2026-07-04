import Foundation

struct TabBarConfig: Codable {
    let tabs: [TabItemConfig]
    var selection: String
    let accentColor: Int?
    let minimizeBehavior: String?  // "automatic" | "onScrollDown" | "onScrollUp" | "never"
}

struct TabItemConfig: Codable, Identifiable {
    let title: String
    let systemImage: String?
    let id: String
    let role: String?
}

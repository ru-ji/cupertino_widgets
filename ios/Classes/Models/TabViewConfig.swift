import Foundation

struct TabViewConfig: Codable {
    let tabs: [TabItemConfig]
    var selection: String
    let accentColor: Int?
}

struct TabItemConfig: Codable, Identifiable {
    let title: String
    let systemImage: String?
    let id: String
    let role: String?
}

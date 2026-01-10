import Foundation

struct SegmentedControlConfig: Codable {
    let items: [String]
    let selectedIndex: Int
    let color: Int?  // Tint color
}

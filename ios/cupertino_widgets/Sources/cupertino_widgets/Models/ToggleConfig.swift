import Foundation

struct ToggleConfig: Codable {
    let label: String?
    let value: Bool
    let color: Int?  // Tint color
    let fontSize: Double?
    let fontWeight: Int?
    let textColor: Int?
}

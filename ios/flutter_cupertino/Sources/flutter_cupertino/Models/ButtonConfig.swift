import Foundation

struct ButtonConfig: Codable {
    let title: String
    let systemImage: String?
    let style: String  // "automatic", "filled", etc.
    let color: Int?  // ARGB Int
    let controlSize: String?  // "mini", "small", "regular", "large", "extraLarge"
    let borderShape: String?  // "automatic", "capsule", "circle", "roundedRectangle"
    let labelStyle: String?  // "automatic", "iconOnly", "titleAndIcon", "titleOnly"
    let expand: Bool?
    let fontSize: Double?
    let fontWeight: Int?
    let textColor: Int?
}

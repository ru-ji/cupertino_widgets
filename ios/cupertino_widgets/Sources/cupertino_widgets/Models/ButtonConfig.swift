import Foundation

struct ButtonConfig: Codable {
    let title: String
    let icon: IconConfig?  // SF Symbol or Flutter glyph
    let style: String  // "automatic", "filled", etc.
    let color: Int?  // ARGB Int
    let controlSize: String?  // "mini", "small", "regular", "large", "extraLarge"
    let borderShape: String?  // "automatic", "capsule", "circle", "roundedRectangle"
    let labelStyle: String?  // "automatic", "iconOnly", "titleAndIcon", "titleOnly"
    let expand: Bool?
    let fontSize: Double?
    let fontWeight: Int?
    let textColor: Int?
    /// Explicit point size from Dart. Sizes the SwiftUI control itself, not
    /// just the Flutter box around it.
    let width: Double?
    let height: Double?
}

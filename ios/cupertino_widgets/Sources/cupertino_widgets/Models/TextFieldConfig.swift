import Foundation

/// Creation/update parameters for the native text field platform view,
/// mirroring the customization surface of `CupertinoNativeTextField` on Dart.
struct TextFieldConfig: Codable {
    let text: String?
    let placeholder: String?
    let keyboardType: String?  // "text" | "number" | "emailAddress" | ...
    let textInputAction: String?  // "done" | "next" | "search" | ...
    let obscureText: Bool?
    let autocorrect: Bool?
    let enableSuggestions: Bool?
    let textCapitalization: String?  // "none" | "words" | "sentences" | "characters"
    let textAlign: String?  // "left" | "right" | "center" | "start" | "end"
    let maxLength: Int?
    let enabled: Bool?
    let readOnly: Bool?
    let autofocus: Bool?
    let fontSize: Double?
    let fontWeight: Int?  // Flutter FontWeight.index (0...8)
    let textColor: Int?  // ARGB
    let cursorColor: Int?  // ARGB
    let clearButtonMode: String?  // "never" | "whileEditing" | "unlessEditing" | "always"
    let textContentType: String?
    let isDark: Bool?  // Flutter brightness → override UITextField appearance
    let backgroundColor: Int?  // ARGB — nil = transparent (iOS default)
    let glass: Bool?  // Liquid Glass background (iOS 26; material fallback below)
    let glassCornerRadius: Double?  // glass shape radius; nil = 16
    let glassTint: Int?  // ARGB tint mixed into the glass
    let prefixIcon: IconConfig?  // leading SF Symbol (UITextField.leftView)
    let suffixIcon: IconConfig?  // trailing SF Symbol (UITextField.rightView)
    let verticalAlignment: String?  // "top" | "center" | "bottom"
}

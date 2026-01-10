import SwiftUI

struct AdaptiveButtonView: View {
    let config: ButtonConfig
    let onPressed: () -> Void

    var tintColor: Color? {
        guard let val = config.color else { return nil }
        let a = Double((val >> 24) & 0xFF) / 255.0
        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8) & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b, opacity: a)
    }

    var body: some View {
        if #available(iOS 15.0, *) {
            modernContent
        } else {
            legacyContent
        }
    }

    // MARK: - Legacy Content (iOS 13/14)

    @ViewBuilder
    var legacyContent: some View {
        let button = Button(action: onPressed) {
            HStack {
                if let sysImg = config.systemImage {
                    Image(systemName: sysImg)
                }
                Text(config.title)
            }
            .font(customFont)
            .padding(legacyPadding)
            .background(legacyBackgroundColor)
            .foregroundColor(customTextColor ?? legacyForegroundColor)
        }

        applyLegacyClip(to: button)
    }

    var legacyPadding: EdgeInsets {
        switch config.controlSize {
        case "mini": return EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8)
        case "small": return EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
        case "large": return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        default: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        }
    }

    var legacyBackgroundColor: Color {
        let color = tintColor ?? Color.blue
        switch config.style {
        case "filled": return color
        case "tinted": return color.opacity(0.15)
        case "plain": return Color.clear
        case "glass", "glassProminent": return Color.gray.opacity(0.1)  // Simple fallback
        default: return Color.clear
        }
    }

    var legacyForegroundColor: Color {
        let color = tintColor ?? Color.blue
        switch config.style {
        case "filled": return .white
        default: return color
        }
    }

    @ViewBuilder
    func applyLegacyClip(to view: some View) -> some View {
        if config.borderShape == "circle" {
            view.clipShape(Circle())
        } else if config.borderShape == "capsule" {
            view.clipShape(Capsule())
        } else {
            view.clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - iOS 15+ Content

    @available(iOS 15.0, *)
    var modernContent: some View {
        // Using standard SwiftUI Button with Label to preserve system behaviors

        let button = Button(action: onPressed) {
            if let sysImg = config.systemImage {
                applyCustomTextColor(to: Label(config.title, systemImage: sysImg).font(customFont))
                    .applyExpand(config.expand ?? false)
            } else {
                applyCustomTextColor(to: Text(config.title).font(customFont))
                    .applyExpand(config.expand ?? false)
            }
        }

        // Label style must be applied to the button view hierarchy to affect Label inside
        let labeledButton = applyLabelStyle(button)

        // Apply Native Styles using the user's Group { switch } structure
        return Group {
            switch config.style {
            case "filled":
                labeledButton
                    .buttonStyle(.borderedProminent)
                    .tint(tintColor)
            case "tinted":
                labeledButton
                    .buttonStyle(.bordered)
                    .tint(tintColor)
            case "plain":
                labeledButton
                    .buttonStyle(.borderless)
                    .foregroundStyle(tintColor ?? .accentColor)
            case "glass":
                if #available(iOS 26.0, *) {
                    labeledButton.buttonStyle(
                        .glass
                    ).tint(tintColor)
                } else {
                    // Manual Fallback for glass
                    let b =
                        labeledButton
                        .buttonStyle(.borderless)
                        .background(tintColor?.opacity(0.2) ?? Color.clear)
                        .background(.thinMaterial)
                        .foregroundStyle(tintColor ?? .primary)

                    applyClipShape(to: b, shape: config.borderShape)
                }
            case "glassProminent":
                if #available(iOS 26.0, *) {
                    labeledButton.buttonStyle(
                        .glassProminent
                    ).tint(tintColor)
                } else {
                    // Manual Fallback for glass prominent
                    let b =
                        labeledButton
                        .buttonStyle(.borderless)
                        .background(tintColor?.opacity(0.4) ?? Color.clear)
                        .background(.ultraThinMaterial)
                        .foregroundStyle(tintColor ?? .primary)

                    applyClipShape(to: b, shape: config.borderShape)
                }
            default:
                labeledButton
                    .buttonStyle(.automatic)
            }
        }
        .controlSize(controlSizeValue)
        .applyButtonShape(config.borderShape)
    }

    @available(iOS 15.0, *)
    @ViewBuilder
    func applyClipShape(to view: some View, shape: String?) -> some View {
        if shape == "circle" {
            view.clipShape(Circle())
        } else if shape == "capsule" {
            view.clipShape(Capsule())
        } else {
            view.clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @available(iOS 15.0, *)
    @ViewBuilder
    func applyLabelStyle(_ view: some View) -> some View {
        switch config.labelStyle {
        case "iconOnly": view.labelStyle(.iconOnly)
        case "titleOnly": view.labelStyle(.titleOnly)
        case "titleAndIcon": view.labelStyle(.titleAndIcon)
        default: view.labelStyle(.automatic)
        }
    }

    @available(iOS 15.0, *)
    var controlSizeValue: ControlSize {
        switch config.controlSize {
        case "mini": return .mini
        case "small": return .small
        case "large": return .large
        case "extraLarge":
            if #available(iOS 17.0, *) {
                return .extraLarge
            } else {
                return .large
            }
        default: return .regular
        }
    }

    // MARK: - Text Style Helpers

    var customFont: Font? {
        if let size = config.fontSize {
            if let weightIndex = config.fontWeight {
                return .system(size: size).weight(weightIndexToFontWeight(weightIndex))
            }
            return .system(size: size)
        }
        if let weightIndex = config.fontWeight {
            return .body.weight(weightIndexToFontWeight(weightIndex))
        }
        return nil
    }

    func weightIndexToFontWeight(_ index: Int) -> Font.Weight {
        switch index {
        case 0: return .ultraLight
        case 1: return .thin
        case 2: return .light
        case 3: return .regular
        case 4: return .medium
        case 5: return .semibold
        case 6: return .bold
        case 7: return .heavy
        case 8: return .black
        default: return .regular
        }
    }

    var customTextColor: Color? {
        guard let val = config.textColor else { return nil }
        let a = Double((val >> 24) & 0xFF) / 255.0
        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8) & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b, opacity: a)
    }

    @ViewBuilder
    func applyCustomTextColor(to view: some View) -> some View {
        if let color = customTextColor {
            if #available(iOS 15.0, *) {
                view.foregroundStyle(color)
            } else {
                view.foregroundColor(color)
            }
        } else {
            view
        }
    }
}

// MARK: - Styles & Extensions

@available(iOS 15.0, *)
extension View {
    @ViewBuilder
    func applyButtonShape(_ shape: String?) -> some View {
        if #available(iOS 15.0, *) {
            switch shape {
            case "capsule":
                self.buttonBorderShape(.capsule)
            case "roundedRectangle":
                self.buttonBorderShape(.roundedRectangle)
            case "circle":
                if #available(iOS 17.0, *) {
                    self.buttonBorderShape(.circle)
                } else {
                    self.buttonBorderShape(.capsule)  // Fallback
                }
            default:
                self.buttonBorderShape(.automatic)
            }
        } else {
            self
        }
    }

    @ViewBuilder
    func applyExpand(_ expand: Bool) -> some View {
        if expand {
            self.frame(maxWidth: .infinity)
        } else {
            self
        }
    }
}

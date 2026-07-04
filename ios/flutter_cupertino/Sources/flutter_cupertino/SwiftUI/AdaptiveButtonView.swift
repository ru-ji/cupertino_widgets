import SwiftUI

struct AdaptiveButtonView: View {
    let config: ButtonConfig
    let onPressed: () -> Void

    var tintColor: Color? {
        guard let val = config.color else { return nil }
        return Color(argb: val)
    }

    var body: some View {
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

    @ViewBuilder
    func applyLabelStyle(_ view: some View) -> some View {
        switch config.labelStyle {
        case "iconOnly": view.labelStyle(.iconOnly)
        case "titleOnly": view.labelStyle(.titleOnly)
        case "titleAndIcon": view.labelStyle(.titleAndIcon)
        default: view.labelStyle(.automatic)
        }
    }

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
                return .system(size: size).weight(Font.Weight(weightIndex: weightIndex))
            }
            return .system(size: size)
        }
        if let weightIndex = config.fontWeight {
            return .body.weight(Font.Weight(weightIndex: weightIndex))
        }
        return nil
    }

    var customTextColor: Color? {
        guard let val = config.textColor else { return nil }
        return Color(argb: val)
    }

    @ViewBuilder
    func applyCustomTextColor(to view: some View) -> some View {
        if let color = customTextColor {
            view.foregroundStyle(color)
        } else {
            view
        }
    }
}

// MARK: - Styles & Extensions

extension View {
    @ViewBuilder
    func applyButtonShape(_ shape: String?) -> some View {
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

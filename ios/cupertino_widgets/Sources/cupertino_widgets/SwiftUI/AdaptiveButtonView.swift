import SwiftUI

@available(iOS 15.0, *)
struct AdaptiveButtonView: View {
    let config: ButtonConfig
    let onPressed: () -> Void

    var tintColor: Color? {
        guard let val = config.color else { return nil }
        return Color(argb: val)
    }

    var body: some View {
        // Using standard SwiftUI Button with Label to preserve system behaviors

        // An explicit size has to reach the LABEL, not just wrap the styled
        // button. A `Button` is not a flexible view: framing it from the
        // outside proposes a size it declines and centers itself in, so the
        // control — and the glass background the style draws around it — stays
        // at its natural size inside a bigger box. Letting the label fill
        // instead makes the background stretch, and the outer frame then holds
        // the whole control to the size that was asked for.
        let fills = config.expand == true || config.width != nil || config.height != nil

        let button = Button(action: onPressed) {
            if let icon = config.icon {
                applyCustomTextColor(
                    to: Label {
                        Text(config.title).font(customFont)
                    } icon: {
                        IconView(icon: icon)
                    }
                )
                .applyFill(fills, bothAxes: config.height != nil)
            } else {
                applyCustomTextColor(to: Text(config.title).font(customFont))
                    .applyFill(fills, bothAxes: config.height != nil)
            }
        }

        // Label style must be applied to the button view hierarchy to affect Label inside
        let labeledButton = button.applyLabelStyle(config.labelStyle)

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
                    labeledButton.buttonStyle(.glass).tint(tintColor)
                } else {
                    // Nothing hand-rolled below 26: a stacked material with a
                    // clipShape sat on top of a button style that already draws
                    // its own background, and ignored `buttonBorderShape`.
                    // The system's bordered style is the honest approximation.
                    labeledButton.buttonStyle(.bordered).tint(tintColor)
                }
            case "glassProminent":
                if #available(iOS 26.0, *) {
                    labeledButton.buttonStyle(.glassProminent).tint(tintColor)
                } else {
                    labeledButton.buttonStyle(.borderedProminent).tint(tintColor)
                }
            default:
                labeledButton
                    .buttonStyle(.automatic)
            }
        }
        .applyControlSize(config.controlSize)
        .applyButtonShape(config.borderShape)
        // An explicit size from Dart wins over the style's own metrics: paired
        // with the filling label above, the background (glass included) is
        // drawn to exactly this frame instead of to whatever padding the style
        // happens to put around the glyph.
        .applyExplicitSize(width: config.width, height: config.height)
        // When Flutter transforms (rotates/scales) the platform view, the
        // engine sets the native view's frame to the transformed BOUNDING BOX
        // — without this, the button stretches to fill that inflated frame
        // and its glass/background balloons. fixedSize keeps the button at
        // its natural size (centered) no matter what frame it's given.
        // expand:true deliberately fills the frame, so it keeps stretching.
        .applyFixedSize(config.expand != true && config.width == nil && config.height == nil)
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

@available(iOS 15.0, *)
extension View {
    /// Pins the control to an explicit point size. A nil axis is left to the
    /// control's own metrics.
    @ViewBuilder
    func applyExplicitSize(width: Double?, height: Double?) -> some View {
        if width != nil || height != nil {
            self.frame(width: width.map { CGFloat($0) }, height: height.map { CGFloat($0) })
        } else {
            self
        }
    }

    /// Which halves of a `Label` the control shows. `iconOnly` is what makes a
    /// circular control possible at all: `buttonBorderShape(.circle)` only
    /// rounds a control whose content is square, so a label carrying text is
    /// laid out as a capsule whatever shape is asked for.
    @ViewBuilder
    func applyLabelStyle(_ style: String?) -> some View {
        switch style {
        case "iconOnly": self.labelStyle(.iconOnly)
        case "titleOnly": self.labelStyle(.titleOnly)
        case "titleAndIcon": self.labelStyle(.titleAndIcon)
        default: self.labelStyle(.automatic)
        }
    }

    /// SwiftUI's `ControlSize`: the control's metrics, not an explicit size.
    @ViewBuilder
    func applyControlSize(_ size: String?) -> some View {
        switch size {
        case "mini": self.controlSize(.mini)
        case "small": self.controlSize(.small)
        case "large": self.controlSize(.large)
        case "extraLarge":
            if #available(iOS 17.0, *) {
                self.controlSize(.extraLarge)
            } else {
                self.controlSize(.large)
            }
        default: self.controlSize(.regular)
        }
    }

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

    /// Lets a button's label fill the space the style offers, so the style's
    /// background stretches with it. `bothAxes` for an explicit height —
    /// `expand` alone is a width-only concept (a full-width button keeps its
    /// natural height).
    @ViewBuilder
    func applyFill(_ fill: Bool, bothAxes: Bool) -> some View {
        if fill {
            self.frame(maxWidth: .infinity, maxHeight: bothAxes ? .infinity : nil)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyFixedSize(_ fixed: Bool) -> some View {
        if fixed {
            self.fixedSize()
        } else {
            self
        }
    }
}

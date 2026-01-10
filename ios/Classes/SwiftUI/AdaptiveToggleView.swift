import SwiftUI

struct AdaptiveToggleView: View {
    let config: ToggleConfig
    let onAction: (Bool) -> Void

    @State private var isOn: Bool

    init(config: ToggleConfig, onAction: @escaping (Bool) -> Void) {
        self.config = config
        self.onAction = onAction
        _isOn = State(initialValue: config.value)
    }

    var body: some View {
        Group {
            if let label = config.label {
                Toggle(isOn: binding) {
                    Text(label)
                        .font(customFont)
                        .foregroundColor(customTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Toggle(isOn: binding) {
                    EmptyView()
                }
                .labelsHidden()
            }
        }
        .applyToggleStyle(tintColor)
    }

    var binding: Binding<Bool> {
        Binding(
            get: { isOn },
            set: { newValue in
                isOn = newValue
                onAction(newValue)
            }
        )
    }

    // MARK: - Style Helpers

    var tintColor: Color? {
        guard let val = config.color else { return nil }
        let a = Double((val >> 24) & 0xFF) / 255.0
        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8) & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b, opacity: a)
    }

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
}

extension View {
    @ViewBuilder
    func applyToggleStyle(_ color: Color?) -> some View {
        if #available(iOS 15.0, *) {
            if let color = color {
                self.toggleStyle(SwitchToggleStyle(tint: color))
            } else {
                self.toggleStyle(SwitchToggleStyle())
            }
        } else {
            self.accentColor(color)
        }
    }
}

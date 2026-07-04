import SwiftUI

struct AdaptiveSegmentedControlView: View {
    let config: SegmentedControlConfig
    let onAction: (Int) -> Void

    @State private var selectedIndex: Int

    init(config: SegmentedControlConfig, onAction: @escaping (Int) -> Void) {
        self.config = config
        self.onAction = onAction
        _selectedIndex = State(initialValue: config.selectedIndex)
    }

    var body: some View {
        Picker("Options", selection: binding) {
            ForEach(0..<config.items.count, id: \.self) { index in
                Text(config.items[index]).tag(index)
            }
        }
        .pickerStyle(.segmented)
        .applySegmentedTint(tintColor)
    }

    var binding: Binding<Int> {
        Binding(
            get: { selectedIndex },
            set: { newValue in
                selectedIndex = newValue
                onAction(newValue)
            }
        )
    }

    // MARK: - Style Helpers

    var tintColor: Color? {
        guard let val = config.color else { return nil }
        return Color(argb: val)
    }
}

extension View {
    @ViewBuilder
    func applySegmentedTint(_ color: Color?) -> some View {
        if let color = color {
            self.colorMultiply(color)
        } else {
            self
        }
    }
}

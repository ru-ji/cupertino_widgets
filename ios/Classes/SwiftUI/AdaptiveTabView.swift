import SwiftUI

@available(iOS 14.0, *)
struct AdaptiveTabView: View {
    var config: TabViewConfig
    let onSelectionChanged: (String) -> Void

    @State private var localSelection: String

    init(config: TabViewConfig, onSelectionChanged: @escaping (String) -> Void) {
        self.config = config
        self.onSelectionChanged = onSelectionChanged
        _localSelection = State(initialValue: config.selection)
    }

    var body: some View {
        TabView(selection: $localSelection) {
            ForEach(config.tabs) { tab in
                Color.clear
                    .tabItem {
                        if let img = tab.systemImage {
                            Label(tab.title, systemImage: img)
                        } else {
                            Text(tab.title)
                        }
                    }
                    .tag(tab.id)
            }
        }
        .accentColor(colorFromInt(config.accentColor))
        .onChange(of: localSelection) { newValue in
            if newValue != config.selection {
                onSelectionChanged(newValue)
            }
        }
        .onChange(of: config.selection) { newValue in
            localSelection = newValue
        }
    }

    private func colorFromInt(_ value: Int?) -> Color? {
        guard let value = value else { return nil }
        return Color(
            UIColor(
                red: CGFloat((value >> 16) & 0xFF) / 255.0,
                green: CGFloat((value >> 8) & 0xFF) / 255.0,
                blue: CGFloat(value & 0xFF) / 255.0,
                alpha: CGFloat((value >> 24) & 0xFF) / 255.0
            ))
    }
}

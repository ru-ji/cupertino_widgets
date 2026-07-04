import SwiftUI

/// Maps `AppBarConfig` entries to system toolbar items for scaffold pages.
/// Each entry gets its own ToolbarItem (own glass capsule on iOS 26); a
/// "group" entry renders its buttons in one HStack sharing a capsule.
/// Supports up to 4 entries per side.
@available(iOS 16.0, *)
struct AppBarToolbar: ToolbarContent {
    let config: AppBarConfig
    let onAction: (String) -> Void

    var body: some ToolbarContent {
        if let e = entry(config.leading, 0) {
            ToolbarItem(placement: .navigationBarLeading) { entryView(e) }
        }
        if let e = entry(config.leading, 1) {
            ToolbarItem(placement: .navigationBarLeading) { entryView(e) }
        }
        if let e = entry(config.leading, 2) {
            ToolbarItem(placement: .navigationBarLeading) { entryView(e) }
        }
        if let e = entry(config.leading, 3) {
            ToolbarItem(placement: .navigationBarLeading) { entryView(e) }
        }
        if let e = entry(config.trailing, 0) {
            ToolbarItem(placement: .navigationBarTrailing) { entryView(e) }
        }
        if let e = entry(config.trailing, 1) {
            ToolbarItem(placement: .navigationBarTrailing) { entryView(e) }
        }
        if let e = entry(config.trailing, 2) {
            ToolbarItem(placement: .navigationBarTrailing) { entryView(e) }
        }
        if let e = entry(config.trailing, 3) {
            ToolbarItem(placement: .navigationBarTrailing) { entryView(e) }
        }
    }

    private func entry(_ entries: [BarEntryConfig]?, _ index: Int) -> BarEntryConfig? {
        guard let entries = entries, index < entries.count else { return nil }
        return entries[index]
    }

    @ViewBuilder
    private func entryView(_ entry: BarEntryConfig) -> some View {
        let items = entry.groupItems
        if items.count > 1 {
            HStack {
                ForEach(items, id: \.actionId) { item in
                    barButton(item)
                }
            }
        } else if let item = items.first {
            barButton(item)
        }
    }

    @ViewBuilder
    private func barButton(_ item: BarItemConfig) -> some View {
        Button {
            onAction(item.actionId)
        } label: {
            if let icon = item.icon {
                if let title = item.title {
                    Label(title, systemImage: icon.name)
                } else {
                    symbolImage(icon)
                }
            } else {
                Text(item.title ?? "")
            }
        }
    }

    @ViewBuilder
    private func symbolImage(_ icon: SymbolConfig) -> some View {
        let image = Image(systemName: icon.name)
        let sized = icon.size != nil ? AnyView(image.font(.system(size: icon.size!))) : AnyView(image)
        if let color = icon.color {
            sized.foregroundStyle(Color(argb: color))
        } else {
            sized
        }
    }
}

extension View {
    /// Applies an optional `AppBarConfig` (title, display mode, toolbar items)
    /// to a navigation destination. No-op when `config` is nil.
    @available(iOS 16.0, *)
    @ViewBuilder
    func applyAppBar(_ config: AppBarConfig?, onAction: @escaping (String) -> Void) -> some View {
        if let config = config {
            self
                .navigationTitle(config.title)
                .navigationBarTitleDisplayMode(config.displayMode == "large" ? .large : .inline)
                .toolbar { AppBarToolbar(config: config, onAction: onAction) }
        } else {
            self
        }
    }
}

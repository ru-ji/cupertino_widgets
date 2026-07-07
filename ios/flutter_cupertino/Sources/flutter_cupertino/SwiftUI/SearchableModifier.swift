import Flutter
import SwiftUI

/// A scaffold page body that hosts the Flutter engine inside a native
/// ScrollView. Reused for both searchable roots and pushed pages.
@available(iOS 16.0, *)
struct PageScrollBody: View {
    let engine: FlutterEngine?
    let scrollEdgeEffect: String?

    var body: some View {
        if let engine = engine {
            ScrollView {
                FlutterContentView(engine: engine)
                    .frame(maxWidth: .infinity)
            }
            .applyScrollEdgeEffect(scrollEdgeEffect)
        } else {
            Text("No content")
        }
    }
}

/// Root page body that also reports the `.searchable` field's active state.
///
/// `isSearching` is only delivered to a *descendant* of the view the
/// `.searchable` modifier is attached to, so this dedicated view reads it in
/// its own `body` (the searchable modifier is applied to it in `navStack`).
@available(iOS 16.0, *)
struct SearchablePageBody: View {
    @Environment(\.isSearching) private var isSearching

    let engine: FlutterEngine?
    let scrollEdgeEffect: String?
    let onActiveChange: (Bool) -> Void

    var body: some View {
        PageScrollBody(engine: engine, scrollEdgeEffect: scrollEdgeEffect)
            .onChange(of: isSearching) { newValue in
                onActiveChange(newValue)
            }
    }
}

extension View {
    /// Applies an optional `SearchConfig` as a native `.searchable(...)` field.
    /// No-op when `config` is nil.
    @available(iOS 16.0, *)
    @ViewBuilder
    func applySearchable(
        _ config: SearchConfig?,
        text: Binding<String>,
        onSubmit: @escaping () -> Void
    ) -> some View {
        if let config = config {
            self
                .searchable(
                    text: text,
                    placement: searchFieldPlacement(config.placement),
                    prompt: config.placeholder.map { Text($0) }
                )
                .onSubmit(of: .search, onSubmit)
        } else {
            self
        }
    }
}

/// Maps the Dart `CupertinoNativeSearchPlacement` name to SwiftUI's placement.
@available(iOS 16.0, *)
private func searchFieldPlacement(_ raw: String?) -> SearchFieldPlacement {
    switch raw {
    case "toolbar":
        return .toolbar
    case "navigationBarDrawer":
        return .navigationBarDrawer(displayMode: .automatic)
    case "navigationBarDrawerAlways":
        return .navigationBarDrawer(displayMode: .always)
    default:
        return .automatic
    }
}

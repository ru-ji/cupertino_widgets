import Flutter
import SwiftUI

/// The pure SwiftUI scaffold: NavigationStack (one per tab) + optional
/// TabView, with Flutter-engine bodies embedded inside native ScrollViews.
/// Because the scroll view and the navigation stack are both native, large
/// titles collapse on scroll, the tab bar can minimize (iOS 26), and pushes
/// animate with full system transitions including toolbar morphing.
@available(iOS 16.0, *)
struct ScaffoldView: View {
    @ObservedObject var model: ScaffoldModel
    let onBarAction: (String, String) -> Void  // (route, actionId)

    var body: some View {
        if let tabBar = model.config.tabBar {
            tabbedContent(tabBar)
                .applyTabTint(tabBar.accentColor)
                .applyTabBarMinimizeBehavior(tabBar.minimizeBehavior)
        } else {
            navStack(key: model.config.body ?? "", rootRoute: model.config.body ?? "")
        }
    }

    @ViewBuilder
    private func tabbedContent(_ tabBar: TabBarConfig) -> some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $model.selection) {
                ForEach(tabBar.tabs) { tab in
                    if tab.role == "search" {
                        Tab(
                            tab.title, systemImage: tab.systemImage ?? "magnifyingglass",
                            value: tab.id, role: .search
                        ) {
                            navStack(key: tab.id, rootRoute: tab.id)
                        }
                    } else {
                        Tab(tab.title, systemImage: tab.systemImage ?? "circle", value: tab.id) {
                            navStack(key: tab.id, rootRoute: tab.id)
                        }
                    }
                }
            }
        } else {
            TabView(selection: $model.selection) {
                ForEach(tabBar.tabs) { tab in
                    navStack(key: tab.id, rootRoute: tab.id)
                        .tabItem { tabLabel(tab) }
                        .tag(tab.id)
                }
            }
        }
    }

    private func pathBinding(_ key: String) -> Binding<[PushedRoute]> {
        Binding(
            get: { model.paths[key] ?? [] },
            set: { newValue in
                // NavigationStack syncs its binding on every view update;
                // only publish real changes or the objectWillChange->rebuild
                // loop starves the embedded Flutter views.
                if (model.paths[key] ?? []) != newValue {
                    model.paths[key] = newValue
                }
            }
        )
    }

    @ViewBuilder
    private func navStack(key: String, rootRoute: String) -> some View {
        NavigationStack(path: pathBinding(key)) {
            pageBody(engine: model.rootEngines[rootRoute])
                .applyAppBar(model.config.appBar) { onBarAction(rootRoute, $0) }
                .navigationDestination(for: PushedRoute.self) { pushed in
                    pageBody(engine: model.pushedEngines[pushed.id])
                        .applyAppBar(pushed.appBar) { onBarAction(pushed.route, $0) }
                }
        }
    }

    /// The Flutter view sizes itself to its content (`isAutoResizable`), and
    /// the native ScrollView scrolls it — driving the large-title collapse,
    /// tab-bar minimize, and edge effects with real system scrolling.
    @ViewBuilder
    private func pageBody(engine: FlutterEngine?) -> some View {
        if let engine = engine {
            ScrollView {
                FlutterContentView(engine: engine)
                    .frame(maxWidth: .infinity)
            }
            .applyScrollEdgeEffect(model.config.scrollEdgeEffect)
        } else {
            Text("No content")
        }
    }
}

@ViewBuilder
func tabLabel(_ tab: TabItemConfig) -> some View {
    if let img = tab.systemImage {
        Label(tab.title, systemImage: img)
    } else {
        Text(tab.title)
    }
}

extension View {
    @ViewBuilder
    func applyTabTint(_ argb: Int?) -> some View {
        if let argb = argb {
            self.tint(Color(argb: argb))
        } else {
            self
        }
    }

    @ViewBuilder
    func applyTabBarMinimizeBehavior(_ behavior: String?) -> some View {
        if #available(iOS 26.0, *) {
            switch behavior {
            case "onScrollDown": self.tabBarMinimizeBehavior(.onScrollDown)
            case "onScrollUp": self.tabBarMinimizeBehavior(.onScrollUp)
            case "never": self.tabBarMinimizeBehavior(.never)
            default: self.tabBarMinimizeBehavior(.automatic)
            }
        } else {
            self
        }
    }

    /// iOS 26 Liquid Glass scroll edge effect style; no-op below 26.
    @ViewBuilder
    func applyScrollEdgeEffect(_ style: String?) -> some View {
        if #available(iOS 26.0, *) {
            switch style {
            case "soft": self.scrollEdgeEffectStyle(.soft, for: .all)
            case "hard": self.scrollEdgeEffectStyle(.hard, for: .all)
            default: self
            }
        } else {
            self
        }
    }
}

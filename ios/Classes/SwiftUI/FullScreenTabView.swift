import Flutter
import SwiftUI

@available(iOS 26.0, *)
struct FlutterContentView: UIViewControllerRepresentable {
    let engine: FlutterEngine

    func makeUIViewController(context: Context) -> FlutterViewController {
        let controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        controller.isViewOpaque = false

        controller.isAutoResizable = true
        return controller
    }

    func updateUIViewController(_ uiViewController: FlutterViewController, context: Context) {}

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiViewController: FlutterViewController,
        context: Context
    ) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width
        let intrinsic = uiViewController.view.intrinsicContentSize

        // If Flutter hasn't calculated size yet, provide a fallback
        if intrinsic.height <= 0 || intrinsic.height == UIView.noIntrinsicMetric {
            return CGSize(width: width, height: 400)  // Reasonable default
        }

        return CGSize(width: width, height: intrinsic.height)
    }
}

@available(iOS 26.0, *)
struct FullscreenTabView: View {
    let config: TabViewConfig
    let engines: [String: FlutterEngine]
    let onSelectionChanged: (String) -> Void

    @State private var localSelection: String

    init(
        config: TabViewConfig, engines: [String: FlutterEngine],
        onSelectionChanged: @escaping (String) -> Void
    ) {
        self.config = config
        self.engines = engines
        self.onSelectionChanged = onSelectionChanged
        _localSelection = State(initialValue: config.selection)
    }

    var body: some View {
        TabView(selection: $localSelection) {
            ForEach(config.tabs) { tab in
                if tab.role == "search" {
                    Tab(
                        tab.title, systemImage: tab.systemImage ?? "magnifyingglass", value: tab.id,
                        role: .search
                    ) {
                        tabContent(for: tab)
                    }
                } else {
                    Tab(tab.title, systemImage: tab.systemImage ?? "circle", value: tab.id) {
                        tabContent(for: tab)
                    }
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .accentColor(colorFromInt(config.accentColor))
        .onChange(of: localSelection) { _, newValue in
            if newValue != config.selection {
                onSelectionChanged(newValue)
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: TabItemConfig) -> some View {
        if let engine = engines[tab.id] {
            ScrollView {
                FlutterContentView(engine: engine)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            Text("No content")
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

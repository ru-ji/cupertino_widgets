import Flutter
import SwiftUI
import UIKit

class NativeScaffoldFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NativeScaffoldView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            messenger: messenger
        )
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// One entry in a scaffold NavigationStack path. `id` is unique per push so
/// the same route can be pushed twice and each instance keeps its own engine.
struct PushedRoute: Hashable {
    let id: UUID
    let route: String
    let appBar: AppBarConfig?
}

/// Observable state shared between the platform view (which mutates it from
/// method-channel calls) and the SwiftUI ScaffoldView (which binds to it).
class ScaffoldModel: ObservableObject {
    @Published var config: ScaffoldConfig
    @Published var selection: String {
        didSet {
            if oldValue != selection { onSelectionChanged?(selection) }
        }
    }
    @Published var paths: [String: [PushedRoute]] = [:] {
        didSet { onPathsChanged?(oldValue, paths) }
    }

    // Engine storage lives here so SwiftUI can look bodies up during builds.
    var rootEngines: [String: FlutterEngine] = [:]
    var pushedEngines: [UUID: FlutterEngine] = [:]

    var onSelectionChanged: ((String) -> Void)?
    var onPathsChanged: (([String: [PushedRoute]], [String: [PushedRoute]]) -> Void)?

    init(config: ScaffoldConfig) {
        self.config = config
        self.selection = config.tabBar?.selection ?? config.tabBar?.tabs.first?.id ?? ""
        // Seed every stack key up front so NavigationStack's initial binding
        // sync doesn't structurally change the dictionary (which would
        // publish a change on every view update).
        if let tabBar = config.tabBar {
            for tab in tabBar.tabs { paths[tab.id] = [] }
        } else if let body = config.body {
            paths[body] = []
        }
    }
}

class NativeScaffoldView: NativeHostingView {
    private let channel: FlutterMethodChannel
    private let engineGroup: FlutterEngineGroup
    private let model: ScaffoldModel
    private var bodyChannels: [String: FlutterMethodChannel] = [:]

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        channel = FlutterMethodChannel(
            name: "flutter_cupertino/scaffold_\(viewId)", binaryMessenger: messenger)
        engineGroup = FlutterEngineGroup(name: "scaffold_\(viewId)", project: nil)

        if let argsMap = args as? [String: Any],
            let config = decodeConfig(ScaffoldConfig.self, from: argsMap)
        {
            model = ScaffoldModel(config: config)
        } else {
            model = ScaffoldModel(
                config: ScaffoldConfig(
                    entryPoint: nil, body: nil, appBar: nil, tabBar: nil,
                    scrollEdgeEffect: nil))
        }

        super.init()
        _view.backgroundColor = .clear

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
        model.onSelectionChanged = { [weak self] selection in
            self?.channel.invokeMethod("onTabChanged", arguments: ["selection": selection])
        }
        model.onPathsChanged = { [weak self] old, new in
            self?.pathsDidChange(old: old, new: new)
        }

        createRootEngines()
        attachContent()
    }

    // MARK: - Engines

    private func createRootEngines() {
        let routes: [String]
        if let tabBar = model.config.tabBar {
            routes = tabBar.tabs.map { $0.id }
        } else if let body = model.config.body {
            routes = [body]
        } else {
            routes = []
        }
        for route in routes {
            model.rootEngines[route] = makeEngine(route: route, key: route)
        }
    }

    private func makeEngine(route: String, key: String) -> FlutterEngine {
        // With a custom entry point the raw route is passed through. Without
        // one, the app's own main() runs with a prefixed route that
        // CupertinoNativeScaffold.maybeRun intercepts — no @pragma needed.
        let engine: FlutterEngine
        if let entryPoint = model.config.entryPoint, !entryPoint.isEmpty {
            engine = engineGroup.makeEngine(
                withEntrypoint: entryPoint, libraryURI: nil, initialRoute: route)
        } else {
            engine = engineGroup.makeEngine(
                withEntrypoint: nil, libraryURI: nil, initialRoute: "cn-scaffold://\(route)")
        }
        // Register this plugin's platform-view factories on the spawned
        // engine so package widgets (buttons, toggles, ...) work inside
        // scaffold bodies too.
        if let registrar = engine.registrar(forPlugin: "FlutterCupertinoPlugin") {
            FlutterCupertinoPlugin.register(with: registrar)
        }
        // Well-known channel so body isolates can drive navigation
        // (CupertinoNativeScaffold.push/pop on the Dart side).
        let bodyChannel = FlutterMethodChannel(
            name: "flutter_cupertino/scaffold_body", binaryMessenger: engine.binaryMessenger)
        bodyChannel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
        bodyChannels[key] = bodyChannel
        return engine
    }

    private func attachContent() {
        if #available(iOS 16.0, *) {
            attach(
                AnyView(
                    ScaffoldView(model: model) { [weak self] route, actionId in
                        self?.channel.invokeMethod(
                            "onBarAction", arguments: ["route": route, "id": actionId])
                    }))
        } else {
            attach(AnyView(Text("CupertinoNativeScaffold requires iOS 16.0+")))
        }
    }

    // MARK: - Navigation

    /// Key into `model.paths` for the stack the user is currently looking at.
    private var currentPathKey: String {
        if model.config.tabBar != nil { return model.selection }
        return model.config.body ?? ""
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "push":
            guard let args = call.arguments as? [String: Any],
                let route = args["route"] as? String
            else {
                result(
                    FlutterError(code: "INVALID_ARGS", message: "push requires a route", details: nil))
                return
            }
            var appBar: AppBarConfig? = nil
            if let appBarMap = args["appBar"] as? [String: Any] {
                appBar = decodeConfig(AppBarConfig.self, from: appBarMap)
            }
            let pushed = PushedRoute(id: UUID(), route: route, appBar: appBar)
            model.pushedEngines[pushed.id] = makeEngine(
                route: route, key: pushed.id.uuidString)
            model.paths[currentPathKey, default: []].append(pushed)
            result(nil)
        case "pop":
            if !(model.paths[currentPathKey] ?? []).isEmpty {
                model.paths[currentPathKey]?.removeLast()
            }
            result(nil)
        case "setTitle":
            if let args = call.arguments as? [String: Any],
                let title = args["title"] as? String,
                let bar = model.config.appBar
            {
                model.config = ScaffoldConfig(
                    entryPoint: model.config.entryPoint,
                    body: model.config.body,
                    appBar: AppBarConfig(
                        title: title, displayMode: bar.displayMode,
                        leading: bar.leading, trailing: bar.trailing),
                    tabBar: model.config.tabBar,
                    scrollEdgeEffect: model.config.scrollEdgeEffect)
            }
            result(nil)
        case "updateScaffold":
            if let argsMap = call.arguments as? [String: Any],
                let config = decodeConfig(ScaffoldConfig.self, from: argsMap)
            {
                // Bars/tabs update in place; engines are kept as-is.
                model.config = config
                // Seed stack keys for any newly added tabs.
                if let tabBar = config.tabBar {
                    for tab in tabBar.tabs where model.paths[tab.id] == nil {
                        model.paths[tab.id] = []
                    }
                }
                if let selection = config.tabBar?.selection, selection != model.selection {
                    model.selection = selection
                }
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func pathsDidChange(old: [String: [PushedRoute]], new: [String: [PushedRoute]]) {
        let oldIds = Set(old.values.flatMap { $0 }.map { $0.id })
        let newIds = Set(new.values.flatMap { $0 }.map { $0.id })

        for removed in oldIds.subtracting(newIds) {
            bodyChannels.removeValue(forKey: removed.uuidString)
            guard let engine = model.pushedEngines.removeValue(forKey: removed) else { continue }
            // Keep the engine alive until the pop transition finishes so the
            // outgoing page stays rendered mid-animation.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                engine.destroyContext()
            }
        }

        let key = currentPathKey
        let routes = [key] + (new[key] ?? []).map { $0.route }
        channel.invokeMethod("onRouteChanged", arguments: ["routes": routes])
    }
}

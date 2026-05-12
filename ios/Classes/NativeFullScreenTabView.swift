import Flutter
import SwiftUI
import UIKit

class NativeFullscreenTabViewFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeFullscreenTabView(
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

class NativeFullscreenTabView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var channel: FlutterMethodChannel
    private var config: TabViewConfig?
    private var hostingController: UIHostingController<AnyView>?
    private var engineGroup: FlutterEngineGroup
    private var engines: [String: FlutterEngine] = [:]

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        _view = UIView(frame: frame)
        _view.backgroundColor = .clear
        channel = FlutterMethodChannel(
            name: "flutter_cupertino/fullscreen_tabview_\(viewId)",
            binaryMessenger: messenger
        )
        engineGroup = FlutterEngineGroup(name: "fullscreen_tabview_\(viewId)", project: nil)

        super.init()

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }

        if let argsMap = args as? [String: Any],
            let config = decodeConfig(from: argsMap)
        {
            self.config = config
            createEngines(for: config)
            createSwiftUIView(config: config)
        }
    }

    func view() -> UIView {
        return _view
    }

    private func createEngines(for config: TabViewConfig) {
        guard let entryPoint = config.entryPoint, !entryPoint.isEmpty else { return }
        for tab in config.tabs {
            let engine = engineGroup.makeEngine(
                withEntrypoint: entryPoint, libraryURI: nil, initialRoute: tab.id)
            engines[tab.id] = engine
        }
    }

    private func destroyEngines() {
        for (_, engine) in engines {
            engine.destroyContext()
        }
        engines.removeAll()
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateFullscreenTabView":
            if let argsMap = call.arguments as? [String: Any],
                let config = decodeConfig(from: argsMap)
            {
                self.config = config
                destroyEngines()
                createEngines(for: config)
                updateSwiftUIView(config: config)
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func createSwiftUIView(config: TabViewConfig) {
        if #available(iOS 26.0, *) {
            let swiftUIView = FullscreenTabView(
                config: config,
                engines: engines,
                onSelectionChanged: { [weak self] newSelection in
                    self?.channel.invokeMethod(
                        "onSelectionChanged", arguments: ["selection": newSelection])
                }
            )
            hostingController = UIHostingController(rootView: AnyView(swiftUIView))
        } else {
            hostingController = UIHostingController(
                rootView: AnyView(Text("FullscreenTabView requires iOS 26.0+")))
        }

        if let hostView = hostingController?.view {
            hostView.backgroundColor = .clear
            hostView.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(hostView)
            NSLayoutConstraint.activate([
                hostView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                hostView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                hostView.topAnchor.constraint(equalTo: _view.topAnchor),
                hostView.bottomAnchor.constraint(equalTo: _view.bottomAnchor),
            ])
        }
    }

    private func updateSwiftUIView(config: TabViewConfig) {
        if #available(iOS 26.0, *) {
            hostingController?.rootView = AnyView(
                FullscreenTabView(
                    config: config,
                    engines: engines,
                    onSelectionChanged: { [weak self] newSelection in
                        self?.channel.invokeMethod(
                            "onSelectionChanged", arguments: ["selection": newSelection])
                    }
                ))
        }
    }

    private func decodeConfig(from args: [String: Any]) -> TabViewConfig? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: args, options: [])
            let config = try JSONDecoder().decode(TabViewConfig.self, from: jsonData)
            return config
        } catch {
            print("Error decoding FullscreenTabView config: \(error)")
            return nil
        }
    }
}

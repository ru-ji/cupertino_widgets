import Flutter
import SwiftUI
import UIKit

class NativeTabViewFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeTabView(
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

class NativeTabView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var channel: FlutterMethodChannel?
    private var hostingController: UIViewController?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        _view = UIView()
        super.init()

        channel = FlutterMethodChannel(
            name: "flutter_cupertino/tabview_\(viewId)", binaryMessenger: messenger)
        channel?.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handle(call, result: result)
        })

        if let argsMap = args as? [String: Any],
            let config = decodeConfig(from: argsMap)
        {
            if #available(iOS 14.0, *) {
                setupSwiftUI(with: config)
            } else {
                // Fallback for iOS < 14 if needed (TabView exists but onChange doesn't)
                // For now, we only support iOS 14+ efficiently or gracefully degrade.
                // Since AdaptiveMenuView had fallback, we might need one here.
                // But TabView is iOS 13+.
                // However, our AdaptiveTabView uses onChange which is iOS 14.
            }
        }
    }

    func view() -> UIView {
        return _view
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "updateTabView" {
            if let argsMap = call.arguments as? [String: Any],
                let config = decodeConfig(from: argsMap)
            {
                if #available(iOS 14.0, *) {
                    setupSwiftUI(with: config)
                }
            }
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func decodeConfig(from args: [String: Any]) -> TabViewConfig? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: args, options: [])
            let config = try JSONDecoder().decode(TabViewConfig.self, from: jsonData)
            return config
        } catch {
            print("Error decoding TabView config: \(error)")
            return nil
        }
    }

    @available(iOS 14.0, *)
    private func setupSwiftUI(with config: TabViewConfig) {
        let tabView = AdaptiveTabView(config: config) { [weak self] selection in
            self?.channel?.invokeMethod("onSelectionChanged", arguments: ["selection": selection])
        }

        if let host = hostingController as? UIHostingController<AdaptiveTabView> {
            host.rootView = tabView
            // Ensure view is laid out
            host.view.setNeedsLayout()
        } else {
            let host = UIHostingController(rootView: tabView)
            host.view.backgroundColor = .clear
            // Important: if we want the standard Tab Bar look, we might not want clear background for the tab bar itself,
            // but the content area should be clear.
            // TabView usually manages its own background.

            _view.addSubview(host.view)
            host.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                host.view.topAnchor.constraint(equalTo: _view.topAnchor),
                host.view.bottomAnchor.constraint(equalTo: _view.bottomAnchor),
                host.view.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            ])
            hostingController = host
        }
    }
}

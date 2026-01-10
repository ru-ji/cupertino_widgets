import Flutter
import SwiftUI
import UIKit

class NativeMenuFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeMenuView(
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

class NativeMenuView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var channel: FlutterMethodChannel?
    private var hostingController: UIHostingController<AdaptiveMenuView>?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        _view = UIView()
        super.init()

        channel = FlutterMethodChannel(
            name: "flutter_cupertino/menu_\(viewId)", binaryMessenger: messenger)
        channel?.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handle(call, result: result)
        })

        if let argsMap = args as? [String: Any],
            let config = decodeConfig(from: argsMap)
        {
            setupSwiftUI(with: config)
        }
    }

    func view() -> UIView {
        return _view
    }

    private func decodeConfig(from args: [String: Any]) -> MenuConfiguration? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: args, options: [])
            let config = try JSONDecoder().decode(MenuConfiguration.self, from: jsonData)
            return config
        } catch {
            print("Error decoding configuration: \(error)")
            return nil
        }
    }

    private func setupSwiftUI(with config: MenuConfiguration) {
        let menuView = AdaptiveMenuView(config: config) { [weak self] actionId, value in
            var args: [String: Any] = ["id": actionId]
            if let val = value {
                args["value"] = val
            }
            self?.channel?.invokeMethod("onAction", arguments: args)
        }

        // Remove existing if any
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        let host = UIHostingController(rootView: menuView)
        // Allow transparency
        host.view.backgroundColor = .clear

        // Add to view hierarchy (We need a parent VC technically, but for PlatformView often we can just add subview.
        // Ideally should add to the FlutterViewController but we don't have easy access here without traversing responders.
        // In simple PlatformView implementations adding the view is enough for rendering,
        // but for Menu to present correctly it relies on the responder chain.
        // UIHostingController usually handles this effectively.)

        _view.addSubview(host.view)

        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: _view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: _view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
        ])

        self.hostingController = host
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getIntrinsicSize":
            if let host = hostingController {
                host.view.setNeedsLayout()
                host.view.layoutIfNeeded()
                let fittingSize = host.sizeThatFits(
                    in: CGSize(
                        width: CGFloat.greatestFiniteMagnitude,
                        height: CGFloat.greatestFiniteMagnitude))
                result(["width": Double(fittingSize.width), "height": Double(fittingSize.height)])
            } else {
                result(["width": 0.0, "height": 0.0])
            }
        case "updateMenu":
            if let argsMap = call.arguments as? [String: Any],
                let config = decodeConfig(from: argsMap)
            {
                setupSwiftUI(with: config)
                result(nil)
            } else {
                result(
                    FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

import Flutter
import SwiftUI
import UIKit

class NativeButtonFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeButtonView(
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

class NativeButtonView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var channel: FlutterMethodChannel?
    private var hostingController: UIHostingController<AdaptiveButtonView>?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        _view = UIView()
        super.init()

        channel = FlutterMethodChannel(
            name: "flutter_cupertino/button_\(viewId)", binaryMessenger: messenger)
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

    private func decodeConfig(from args: [String: Any]) -> ButtonConfig? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: args, options: [])
            let config = try JSONDecoder().decode(ButtonConfig.self, from: jsonData)
            return config
        } catch {
            print("Error decoding button configuration: \(error)")
            return nil
        }
    }

    private func setupSwiftUI(with config: ButtonConfig) {
        let buttonView = AdaptiveButtonView(config: config) { [weak self] in
            self?.channel?.invokeMethod("onPressed", arguments: nil)
        }

        // Cleanup old controller
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        let host = UIHostingController(rootView: buttonView)
        host.view.backgroundColor = .clear

        _view.addSubview(host.view)

        host.view.translatesAutoresizingMaskIntoConstraints = false
        // Pin to edges
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
            // Calculate the intrinsic content size from the hosting controller
            if let host = hostingController {
                // Force layout to ensure correct sizing
                host.view.setNeedsLayout()
                host.view.layoutIfNeeded()

                // sizeThatFits is more reliable for SwiftUI views
                let fittingSize = host.sizeThatFits(
                    in: CGSize(
                        width: CGFloat.greatestFiniteMagnitude,
                        height: CGFloat.greatestFiniteMagnitude))
                result(["width": Double(fittingSize.width), "height": Double(fittingSize.height)])
            } else {
                result(["width": 0.0, "height": 0.0])
            }
        case "updateButton":
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

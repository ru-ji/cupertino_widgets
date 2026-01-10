import Flutter
import SwiftUI
import UIKit

class NativeSegmentedControlFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeSegmentedControlView(
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

class NativeSegmentedControlView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var channel: FlutterMethodChannel?
    private var hostingController: UIHostingController<AdaptiveSegmentedControlView>?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        _view = UIView()
        super.init()

        channel = FlutterMethodChannel(
            name: "flutter_cupertino/segmented_\(viewId)", binaryMessenger: messenger)
        channel?.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handle(call, result: result)
        })

        if let argsMap = args as? [String: Any],
            let config = decodeConfig(from: argsMap)
        {
            createSwiftUIView(config: config)
        } else {
            let defaultConfig = SegmentedControlConfig(
                items: ["One", "Two"], selectedIndex: 0, color: nil)
            createSwiftUIView(config: defaultConfig)
        }
    }

    func view() -> UIView {
        return _view
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
        case "updateSegmentedControl":
            if let argsMap = call.arguments as? [String: Any],
                let config = decodeConfig(from: argsMap)
            {
                updateSwiftUIView(config: config)
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func createSwiftUIView(config: SegmentedControlConfig) {
        let swiftUIView = AdaptiveSegmentedControlView(
            config: config,
            onAction: { [weak self] newValue in
                self?.channel?.invokeMethod("onValueChanged", arguments: newValue)
            }
        )

        hostingController = UIHostingController(rootView: swiftUIView)

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

    private func updateSwiftUIView(config: SegmentedControlConfig) {
        hostingController?.rootView = AdaptiveSegmentedControlView(
            config: config,
            onAction: { [weak self] newValue in
                self?.channel?.invokeMethod("onValueChanged", arguments: newValue)
            }
        )
    }

    private func decodeConfig(from map: [String: Any]) -> SegmentedControlConfig? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: map, options: [])
            let config = try JSONDecoder().decode(SegmentedControlConfig.self, from: jsonData)
            return config
        } catch {
            print("Error decoding SegmentedControlConfig: \(error)")
            return nil
        }
    }
}

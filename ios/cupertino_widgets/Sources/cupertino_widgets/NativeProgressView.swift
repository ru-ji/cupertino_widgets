import Flutter
import SwiftUI
import UIKit

@available(iOS 15.0, *)
class NativeProgressFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeProgressView(
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

@available(iOS 15.0, *)
class NativeProgressView: NativeHostingView {
    private var channel: FlutterMethodChannel?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        super.init()

        channel = FlutterMethodChannel(
            name: "cupertino_widgets/progress_\(viewId)", binaryMessenger: messenger)
        channel?.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handle(call, result: result)
        })

        if let argsMap = args as? [String: Any] {
            setupSwiftUI(with: argsMap)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "updateProgress" {
            if let args = call.arguments as? [String: Any] {
                update(AnyView(makeContent(with: args)))
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func setupSwiftUI(with args: [String: Any]) {
        let style = args["style"] as? Int ?? 0
        attach(
            AnyView(makeContent(with: args)),
            configureConstraints: { host, container in
                NSLayoutConstraint.activate([
                    host.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                    host.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                    host.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
                    host.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
                ])
                // If linear, stretch to the full width
                if style == 1 {
                    host.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
                }
            })
    }

    private func makeContent(with args: [String: Any]) -> AdaptiveProgressView {
        let value = args["value"] as? Double
        let total = args["total"] as? Double ?? 1.0
        let label = args["label"] as? String
        let style = args["style"] as? Int ?? 0
        let colorInt = args["color"] as? Int

        let color: Color? = colorInt != nil ? Color(argb: colorInt!) : nil

        return AdaptiveProgressView(
            value: value,
            total: total,
            label: label,
            style: style,
            color: color
        )
    }
}

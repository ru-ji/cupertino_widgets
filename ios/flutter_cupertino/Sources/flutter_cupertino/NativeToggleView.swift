import Flutter
import SwiftUI
import UIKit

class NativeToggleFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeToggleView(
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

class NativeToggleView: NativeHostingView {
    private var channel: FlutterMethodChannel?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        super.init()

        channel = FlutterMethodChannel(
            name: "flutter_cupertino/toggle_\(viewId)", binaryMessenger: messenger)
        channel?.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handle(call, result: result)
        })

        if let argsMap = args as? [String: Any],
            let config = decodeConfig(ToggleConfig.self, from: argsMap)
        {
            createSwiftUIView(config: config)
        } else {
            // Fallback default
            let defaultConfig = ToggleConfig(
                label: nil, value: false, color: nil, fontSize: nil, fontWeight: nil, textColor: nil
            )
            createSwiftUIView(config: defaultConfig)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getIntrinsicSize":
            result(intrinsicSize())
        case "updateToggle":
            if let argsMap = call.arguments as? [String: Any],
                let config = decodeConfig(ToggleConfig.self, from: argsMap)
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

    private func createSwiftUIView(config: ToggleConfig) {
        attach(AnyView(makeContent(config: config)))
    }

    private func updateSwiftUIView(config: ToggleConfig) {
        update(AnyView(makeContent(config: config)))
    }

    private func makeContent(config: ToggleConfig) -> AdaptiveToggleView {
        AdaptiveToggleView(
            config: config,
            onAction: { [weak self] newValue in
                self?.channel?.invokeMethod("onChanged", arguments: newValue)
            }
        )
    }
}

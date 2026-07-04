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

class NativeSegmentedControlView: NativeHostingView {
    private var channel: FlutterMethodChannel?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        super.init()

        channel = FlutterMethodChannel(
            name: "flutter_cupertino/segmented_\(viewId)", binaryMessenger: messenger)
        channel?.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handle(call, result: result)
        })

        if let argsMap = args as? [String: Any],
            let config = decodeConfig(SegmentedControlConfig.self, from: argsMap)
        {
            createSwiftUIView(config: config)
        } else {
            let defaultConfig = SegmentedControlConfig(
                items: ["One", "Two"], selectedIndex: 0, color: nil)
            createSwiftUIView(config: defaultConfig)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getIntrinsicSize":
            result(intrinsicSize())
        case "updateSegmentedControl":
            if let argsMap = call.arguments as? [String: Any],
                let config = decodeConfig(SegmentedControlConfig.self, from: argsMap)
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
        attach(AnyView(makeContent(config: config)))
    }

    private func updateSwiftUIView(config: SegmentedControlConfig) {
        update(AnyView(makeContent(config: config)))
    }

    private func makeContent(config: SegmentedControlConfig) -> AdaptiveSegmentedControlView {
        AdaptiveSegmentedControlView(
            config: config,
            onAction: { [weak self] newValue in
                self?.channel?.invokeMethod("onValueChanged", arguments: newValue)
            }
        )
    }
}

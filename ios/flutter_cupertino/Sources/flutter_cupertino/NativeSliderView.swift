import Flutter
import SwiftUI
import UIKit

class NativeSliderFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeSliderView(
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

class NativeSliderView: NativeHostingView {
    private var channel: FlutterMethodChannel
    private var viewModel = SliderViewModel()

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        channel = FlutterMethodChannel(
            name: "adaptive_slider_\(viewId)", binaryMessenger: messenger)

        super.init()

        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handle(call, result: result)
        })

        if let args = args as? [String: Any] {
            updateViewModel(with: args)
        }

        let sliderView = AdaptiveSliderView(viewModel: viewModel) { [weak self] value in
            self?.channel.invokeMethod("onChanged", arguments: value)
        }
        attach(AnyView(sliderView))
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getIntrinsicSize":
            result(intrinsicSize())
        case "updateProps":
            if let args = call.arguments as? [String: Any] {
                updateViewModel(with: args)
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func updateViewModel(with args: [String: Any]) {
        if let value = args["value"] as? NSNumber {
            viewModel.value = value.doubleValue
        }
        if let min = args["min"] as? NSNumber {
            viewModel.min = min.doubleValue
        }
        if let max = args["max"] as? NSNumber {
            viewModel.max = max.doubleValue
        }
        if let isEnabled = args["isEnabled"] as? Bool {
            viewModel.isEnabled = isEnabled
        }

        // Colors
        if let activeColorVal = args["activeColor"] as? Int {
            viewModel.activeColor = Color(argb: activeColorVal)
        } else {
            viewModel.activeColor = nil
        }

        if let thumbColorVal = args["thumbColor"] as? Int {
            viewModel.thumbColor = Color(argb: thumbColorVal)
        } else {
            viewModel.thumbColor = nil
        }
    }
}

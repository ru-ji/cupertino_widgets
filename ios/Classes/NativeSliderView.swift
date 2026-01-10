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

class NativeSliderView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var channel: FlutterMethodChannel
    private var hostingController: UIHostingController<AdaptiveSliderView>?
    private var viewModel: SliderViewModel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        _view = UIView()
        viewModel = SliderViewModel()
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

        hostingController = UIHostingController(rootView: sliderView)

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
            viewModel.activeColor = Color(intValue: activeColorVal)
        } else {
            viewModel.activeColor = nil
        }

        if let thumbColorVal = args["thumbColor"] as? Int {
            viewModel.thumbColor = Color(intValue: thumbColorVal)
        } else {
            viewModel.thumbColor = nil
        }
    }
}

extension Color {
    init(intValue: Int) {
        let alpha = Double((intValue >> 24) & 0xFF) / 255.0
        let red = Double((intValue >> 16) & 0xFF) / 255.0
        let green = Double((intValue >> 8) & 0xFF) / 255.0
        let blue = Double(intValue & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

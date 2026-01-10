import Flutter
import SwiftUI
import UIKit

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

class NativeProgressView: NSObject, FlutterPlatformView {
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
            name: "flutter_cupertino/progress_\(viewId)", binaryMessenger: messenger)
        channel?.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handle(call, result: result)
        })

        if let argsMap = args as? [String: Any], #available(iOS 14.0, *) {
            setupSwiftUI(with: argsMap)
        } else {
            // Fallback for iOS 13 or invalid args
            // Could show UIActivityIndicatorView or UIProgressView
            setupFallback(with: args as? [String: Any])
        }
    }

    func view() -> UIView {
        return _view
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "updateProgress" {
            if let args = call.arguments as? [String: Any], #available(iOS 14.0, *) {
                updateSwiftUI(with: args)
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    @available(iOS 14.0, *)
    private func updateSwiftUI(with args: [String: Any]) {
        let value = args["value"] as? Double
        let total = args["total"] as? Double ?? 1.0
        let label = args["label"] as? String
        let style = args["style"] as? Int ?? 0
        let colorInt = args["color"] as? Int

        let color: Color? = colorInt != nil ? Color(intValue: colorInt!) : nil

        let swiftUIView = AdaptiveProgressView(
            value: value,
            total: total,
            label: label,
            style: style,
            color: color
        )

        if let hc = hostingController as? UIHostingController<AdaptiveProgressView> {
            hc.rootView = swiftUIView
        }
    }

    @available(iOS 14.0, *)
    private func setupSwiftUI(with args: [String: Any]) {
        let value = args["value"] as? Double
        let total = args["total"] as? Double ?? 1.0
        let label = args["label"] as? String
        let style = args["style"] as? Int ?? 0
        let colorInt = args["color"] as? Int

        let color: Color? = colorInt != nil ? Color(intValue: colorInt!) : nil

        let swiftUIView = AdaptiveProgressView(
            value: value,
            total: total,
            label: label,
            style: style,
            color: color
        )

        let hc = UIHostingController(rootView: swiftUIView)
        self.hostingController = hc

        if let hostView = hc.view {
            hostView.backgroundColor = .clear
            hostView.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(hostView)

            NSLayoutConstraint.activate([
                hostView.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
                hostView.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
                hostView.leadingAnchor.constraint(greaterThanOrEqualTo: _view.leadingAnchor),
                hostView.trailingAnchor.constraint(lessThanOrEqualTo: _view.trailingAnchor),
            ])

            // If linear, maybe stretch width
            if style == 1 {
                hostView.widthAnchor.constraint(equalTo: _view.widthAnchor).isActive = true
            }
        }
    }

    private func setupFallback(with args: [String: Any]?) {
        // Simple fallback for iOS 13
        guard let args = args else { return }
        let style = args["style"] as? Int ?? 0
        let value = args["value"] as? Double
        let colorInt = args["color"] as? Int

        if style == 1 || (style == 0 && value != nil) {
            // Linear -> UIProgressView
            let progressView = UIProgressView(progressViewStyle: .default)
            if let val = value, let total = args["total"] as? Double, total > 0 {
                progressView.progress = Float(val / total)
            }
            if let c = colorInt {
                progressView.tintColor = uiColor(from: c)
            }
            progressView.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(progressView)
            NSLayoutConstraint.activate([
                progressView.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
                progressView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                progressView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            ])
        } else {
            // Circular -> UIActivityIndicatorView
            let indicator = UIActivityIndicatorView(style: .medium)
            indicator.startAnimating()
            if let c = colorInt {
                indicator.color = uiColor(from: c)
            }
            indicator.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(indicator)
            NSLayoutConstraint.activate([
                indicator.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
                indicator.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
            ])
        }
    }

    private func uiColor(from val: Int) -> UIColor {
        let a = CGFloat((val >> 24) & 0xFF) / 255.0
        let r = CGFloat((val >> 16) & 0xFF) / 255.0
        let g = CGFloat((val >> 8) & 0xFF) / 255.0
        let b = CGFloat(val & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

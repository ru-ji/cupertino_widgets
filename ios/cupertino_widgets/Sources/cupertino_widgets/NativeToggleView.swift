import Flutter
import SwiftUI
import UIKit

@available(iOS 15.0, *)
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

@available(iOS 15.0, *)
class NativeToggleView: NativeHostingView {
    private var channel: FlutterMethodChannel?

    /// The value the hosted switch is actually showing. `AdaptiveToggleView`
    /// seeds its `@State` from the config once, when it is first hosted, so
    /// swapping the root view later leaves the switch on the old value — a
    /// value pushed from Dart would simply never arrive. Rebuilding the
    /// hosting controller does apply it, but it also cuts the flip animation
    /// short, so that path is reserved for the case that needs it. The echo of
    /// a flip the user just made natively takes the cheap path.
    private var shownValue = false

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        super.init()

        channel = FlutterMethodChannel(
            name: "cupertino_widgets/toggle_\(viewId)", binaryMessenger: messenger)
        channel?.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handle(call, result: result)
        })

        if let argsMap = args as? [String: Any],
            let config = decodeConfig(ToggleConfig.self, from: argsMap)
        {
            setupSwiftUI(with: config)
        }
    }

    private func setupSwiftUI(with config: ToggleConfig) {
        shownValue = config.value
        let toggleView = makeContent(config: config)
        guard config.label == nil else {
            // A labeled switch is a full-width list row: like the button's
            // `expand`, it fills the box Flutter gave it.
            attach(AnyView(toggleView))
            return
        }
        // Otherwise size the hosting view to the switch's own content and
        // center it, instead of stretching it across the container.
        //
        // The default `attach` pins all four edges, so the switch was drawn to
        // whatever box Flutter had built — which, until the intrinsic size
        // round trip landed, was the Dart-side default. Stretched past its
        // natural 51x31 the control drew outside its own bounds; boxed smaller
        // it was cut. Hugging at required priority keeps it at the size UIKit
        // gives it, and the `lessThanOrEqualTo` pair keeps it inside the box no
        // matter what that box turns out to be — so the asynchronous
        // measurement stops mattering for correctness.
        attach(AnyView(toggleView)) { host, container in
            host.setContentHuggingPriority(.required, for: .horizontal)
            host.setContentHuggingPriority(.required, for: .vertical)
            NSLayoutConstraint.activate([
                host.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                host.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                host.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor),
                host.heightAnchor.constraint(lessThanOrEqualTo: container.heightAnchor),
            ])
        }
    }

    private func makeContent(config: ToggleConfig) -> AdaptiveToggleView {
        AdaptiveToggleView(
            config: config,
            onAction: { [weak self] newValue in
                self?.shownValue = newValue
                self?.channel?.invokeMethod("onChanged", arguments: newValue)
            }
        )
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getIntrinsicSize":
            result(intrinsicSize())
        case "updateToggle":
            if let argsMap = call.arguments as? [String: Any],
                let config = decodeConfig(ToggleConfig.self, from: argsMap)
            {
                if config.value == shownValue {
                    // Label, tint or font only: swap the root view, which keeps
                    // the switch's in-flight animation intact.
                    update(AnyView(makeContent(config: config)))
                } else {
                    setupSwiftUI(with: config)
                }
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

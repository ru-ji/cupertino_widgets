import Flutter
import SwiftUI
import UIKit

@available(iOS 15.0, *)
class NativeListFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeListView(
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

/// Hosts a native SwiftUI `List`/`Form` (see `AdaptiveListView`) as a Flutter
/// platform view. Self-sizes to its content height (measured against the
/// Flutter-provided width) so it can sit inside a Flutter scroll view.
@available(iOS 15.0, *)
class NativeListView: NativeHostingView {
    private var channel: FlutterMethodChannel?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        super.init()

        channel = FlutterMethodChannel(
            name: "cupertino_widgets/list_\(viewId)", binaryMessenger: messenger)
        channel?.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }

        let argsMap = args as? [String: Any]
        let isDark = (argsMap?["isDark"] as? NSNumber)?.boolValue
        if let argsMap = argsMap, let config = decodeConfig(ListConfig.self, from: argsMap) {
            createView(config: config, isDark: isDark)
        } else {
            createView(
                config: ListConfig(
                    variant: "list", style: "insetGrouped", scrollable: false,
                    isDark: nil, cornerRadius: nil, tint: nil, sections: []),
                isDark: isDark)
        }
    }

    private func createView(config: ListConfig, isDark: Bool?) {
        attach(AnyView(makeContent(config)))
        _view.backgroundColor = .clear
        // Give the hosting view a content-based intrinsic size so a
        // scroll-disabled List/Form reports its full height (iOS 16+).
        if #available(iOS 16.0, *) {
            hostingController?.sizingOptions = .intrinsicContentSize
        }
        if let isDark = isDark {
            hostingController?.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
        scheduleSizeReports()
    }

    private func makeContent(_ config: ListConfig) -> AnyView {
        if #available(iOS 15.0, *) {
            return AnyView(
                AdaptiveListView(
                    config: config,
                    onRowTap: { [weak self] id in
                        self?.channel?.invokeMethod("onRowTap", arguments: ["id": id])
                    },
                    onToggle: { [weak self] id, value in
                        self?.channel?.invokeMethod(
                            "onToggle", arguments: ["id": id, "value": value])
                    }
                ))
        } else {
            return AnyView(Text("CupertinoNativeList requires iOS 15.0+"))
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getIntrinsicSize":
            result(intrinsicSize())
        case "updateList":
            if let argsMap = call.arguments as? [String: Any],
                let config = decodeConfig(ListConfig.self, from: argsMap)
            {
                update(AnyView(makeContent(config)))
                if let isDark = (argsMap["isDark"] as? NSNumber)?.boolValue {
                    hostingController?.overrideUserInterfaceStyle = isDark ? .dark : .light
                }
                scheduleSizeReports()
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Measures the list against the Flutter-provided *width* (a `List` needs a
    /// finite width to lay out and report its full content height) rather than
    /// the base class's unbounded measurement.
    override func intrinsicSize() -> [String: Double] {
        let size = measuredSize()
        return ["width": Double(size.width), "height": Double(size.height)]
    }

    private func measuredSize() -> CGSize {
        guard let host = hostingController else { return .zero }
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        let width = _view.bounds.width > 1 ? _view.bounds.width : UIScreen.main.bounds.width

        var height: CGFloat = 0
        // Primary: sizeThatFits asks the UIHostingController for the size
        // its SwiftUI content needs at the given width — the most reliable
        // measurement for a List/Form that self-sizes to its rows.
        let fittingSize = host.sizeThatFits(
            in: CGSize(width: width, height: .greatestFiniteMagnitude))
        if fittingSize.height > 1 && fittingSize.height < 100_000 {
            height = fittingSize.height
        }
        // Fallback: iOS 16+ sizingOptions == .intrinsicContentSize
        if height <= 1, #available(iOS 16.0, *) {
            let intrinsic = host.view.intrinsicContentSize.height
            if intrinsic > 1 && intrinsic < 100_000 { height = intrinsic }
        }
        // Fallback: UIKit auto-layout fitting
        if height <= 1 {
            height = host.view.systemLayoutSizeFitting(
                CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel).height
        }
        return CGSize(width: width, height: height)
    }

    /// Pushes the measured content height to Flutter as layout settles (initial
    /// render, cell rendering, font/async loads), so the fixed platform-view
    /// box grows to fit instead of clipping content.
    private func scheduleSizeReports() {
        let delays: [Double] = [0.0, 0.1, 0.3, 0.6, 1.0, 1.5, 2.0]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.reportContentSize()
            }
        }
    }

    private func reportContentSize() {
        let height = measuredSize().height
        guard height > 1 else { return }
        channel?.invokeMethod("onContentSize", arguments: ["height": Double(height)])
    }
}

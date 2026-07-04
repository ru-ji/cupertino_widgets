import Flutter
import UIKit

class NativeAppBarFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeAppBarView(
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

/// A bare `UINavigationBar` in a transparent container — no
/// NavigationStack/UINavigationController wrapper, so nothing paints a
/// content-area background and Flutter content stays visible behind the
/// bar's glass. The bar is pinned below the status-bar height reported by
/// Flutter so it sits exactly where a native bar would.
class NativeAppBarView: NSObject, FlutterPlatformView {
    private let channel: FlutterMethodChannel
    private let container: UIView
    private let navBar = UINavigationBar(frame: .zero)
    private let navItem = UINavigationItem()

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        channel = FlutterMethodChannel(
            name: "flutter_cupertino/appbar_\(viewId)", binaryMessenger: messenger)
        container = UIView(frame: frame)

        super.init()

        container.backgroundColor = .clear

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.setItems([navItem], animated: false)

        var statusBarHeight: CGFloat = 0
        if let dict = args as? [String: Any] {
            if let n = dict["statusBarHeight"] as? NSNumber {
                statusBarHeight = CGFloat(truncating: n)
            }
        }

        container.addSubview(navBar)
        NSLayoutConstraint.activate([
            navBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            navBar.topAnchor.constraint(
                equalTo: container.topAnchor, constant: statusBarHeight),
            navBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        if let dict = args as? [String: Any] {
            apply(dict)
        }

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    func view() -> UIView { container }

    // MARK: - Configuration

    private func apply(_ dict: [String: Any]) {
        if let title = dict["title"] as? String {
            navItem.title = title
        }
        let large = (dict["displayMode"] as? String) == "large"
        navBar.prefersLargeTitles = large
        navItem.largeTitleDisplayMode = large ? .always : .never
        if let isDark = (dict["isDark"] as? NSNumber)?.boolValue {
            container.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
        if let n = dict["tint"] as? NSNumber {
            navBar.tintColor = UIColor(argb: n.intValue)
        }

        let leadingGroups = buttonGroups(dict["leading"])
        let trailingGroups = buttonGroups(dict["trailing"])
        if #available(iOS 16.0, *) {
            navItem.leadingItemGroups = leadingGroups
            navItem.trailingItemGroups = trailingGroups
        } else {
            navItem.leftBarButtonItems = leadingGroups.flatMap { $0.barButtonItems }
            navItem.rightBarButtonItems =
                trailingGroups.flatMap { $0.barButtonItems }.reversed()
        }
    }

    /// One `UIBarButtonItemGroup` per Dart entry: grouped items share a glass
    /// capsule on iOS 26; separate entries render as separate capsules.
    private func buttonGroups(_ raw: Any?) -> [UIBarButtonItemGroup] {
        guard let list = raw as? [[String: Any]], !list.isEmpty else { return [] }
        return list.compactMap { entry in
            let itemMaps: [[String: Any]]
            if entry["type"] as? String == "group" {
                itemMaps = (entry["items"] as? [[String: Any]]) ?? []
            } else {
                itemMaps = [entry]
            }
            let buttons = itemMaps.compactMap { barButton($0) }
            guard !buttons.isEmpty else { return nil }
            return UIBarButtonItemGroup(barButtonItems: buttons, representativeItem: nil)
        }
    }

    private func barButton(_ item: [String: Any]) -> UIBarButtonItem? {
        guard let actionId = item["actionId"] as? String else { return nil }
        let action = UIAction { [weak self] _ in
            self?.channel.invokeMethod("onBarAction", arguments: ["id": actionId])
        }
        let button: UIBarButtonItem
        if let icon = item["icon"] as? [String: Any],
            let symbolName = icon["name"] as? String
        {
            var image = UIImage(systemName: symbolName)
            if let size = (icon["size"] as? NSNumber)?.doubleValue {
                image = image?.applyingSymbolConfiguration(
                    UIImage.SymbolConfiguration(pointSize: CGFloat(size)))
            }
            button = UIBarButtonItem(image: image, primaryAction: action)
            if let colorVal = (icon["color"] as? NSNumber)?.intValue {
                button.tintColor = UIColor(argb: colorVal)
            }
        } else {
            button = UIBarButtonItem(title: item["title"] as? String, primaryAction: action)
        }
        return button
    }

    // MARK: - Method channel

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getIntrinsicSize":
            let size = navBar.sizeThatFits(
                CGSize(width: container.bounds.width, height: CGFloat.greatestFiniteMagnitude))
            result(["width": Double(size.width), "height": Double(size.height)])
        case "updateAppBar":
            if let dict = call.arguments as? [String: Any] {
                apply(dict)
                result(nil)
            } else {
                result(FlutterError(code: "bad_args", message: "Missing config", details: nil))
            }
        case "setBrightness":
            if let args = call.arguments as? [String: Any],
                let isDark = (args["isDark"] as? NSNumber)?.boolValue
            {
                container.overrideUserInterfaceStyle = isDark ? .dark : .light
                result(nil)
            } else {
                result(FlutterError(code: "bad_args", message: "Missing isDark", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

import Flutter
import SwiftUI
import UIKit

class NativeTabViewFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeTabView(
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

class NativeTabView: NSObject, FlutterPlatformView, UITabBarDelegate {
    private var _view: UIView
    private var tabBar: UITabBar
    private var channel: FlutterMethodChannel
    private var config: TabViewConfig?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        _view = UIView(frame: frame)
        tabBar = UITabBar(frame: .zero)
        channel = FlutterMethodChannel(
            name: "flutter_cupertino/tabview_\(viewId)", binaryMessenger: messenger)

        super.init()

        _view.backgroundColor = .clear
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.delegate = self
        _view.addSubview(tabBar)

        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: _view.bottomAnchor),
            tabBar.topAnchor.constraint(equalTo: _view.topAnchor),
        ])

        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handle(call, result: result)
        })

        if let argsMap = args as? [String: Any] {
            update(with: argsMap)
        }
    }

    func view() -> UIView {
        return _view
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "updateTabView" {
            if let argsMap = call.arguments as? [String: Any] {
                update(with: argsMap)
            }
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func update(with args: [String: Any]) {
        guard let config = decodeConfig(from: args) else { return }
        self.config = config

        var items: [UITabBarItem] = []
        for (index, tab) in config.tabs.enumerated() {
            let item: UITabBarItem
            if let role = tab.role, role == "search" {
                item = UITabBarItem(tabBarSystemItem: .search, tag: index)
            } else {
                item = UITabBarItem(
                    title: tab.title, image: UIImage(systemName: tab.systemImage ?? ""), tag: index)
            }
            items.append(item)
        }
        tabBar.setItems(items, animated: true)

        if let accentColor = config.accentColor {
            tabBar.tintColor = UIColor(
                red: CGFloat((accentColor >> 16) & 0xFF) / 255.0,
                green: CGFloat((accentColor >> 8) & 0xFF) / 255.0,
                blue: CGFloat(accentColor & 0xFF) / 255.0,
                alpha: CGFloat((accentColor >> 24) & 0xFF) / 255.0
            )
        }

        if let index = config.tabs.firstIndex(where: { $0.id == config.selection }) {
            tabBar.selectedItem = tabBar.items?[index]
        }
    }

    private func decodeConfig(from args: [String: Any]) -> TabViewConfig? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: args, options: [])
            let config = try JSONDecoder().decode(TabViewConfig.self, from: jsonData)
            return config
        } catch {
            print("Error decoding TabView config: \(error)")
            return nil
        }
    }

    // UITabBarDelegate
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let index = item.tag
        if let config = config, index < config.tabs.count {
            let tabId = config.tabs[index].id
            channel.invokeMethod("onSelectionChanged", arguments: ["selection": tabId])
        }
    }
}

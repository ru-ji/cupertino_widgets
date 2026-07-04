import Flutter
import UIKit

public class FlutterCupertinoPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let menuFactory = NativeMenuFactory(messenger: registrar.messenger())
        registrar.register(
            menuFactory, withId: "com.example.flutter_cupertino/cupertino_native_menu")

        let buttonFactory = NativeButtonFactory(messenger: registrar.messenger())
        registrar.register(
            buttonFactory, withId: "com.example.flutter_cupertino/cupertino_native_button")

        let toggleFactory = NativeToggleFactory(messenger: registrar.messenger())
        registrar.register(
            toggleFactory, withId: "com.example.flutter_cupertino/cupertino_native_toggle")

        let segmentedFactory = NativeSegmentedControlFactory(messenger: registrar.messenger())
        registrar.register(
            segmentedFactory, withId: "com.example.flutter_cupertino/cupertino_native_segmented")

        let sliderFactory = NativeSliderFactory(messenger: registrar.messenger())
        registrar.register(
            sliderFactory, withId: "com.example.flutter_cupertino/cupertino_native_slider")

        let appBarFactory = NativeAppBarFactory(messenger: registrar.messenger())
        registrar.register(
            appBarFactory, withId: "com.example.flutter_cupertino/cupertino_native_appbar")

        let tabBarFactory = NativeTabBarFactory(messenger: registrar.messenger())
        registrar.register(
            tabBarFactory, withId: "com.example.flutter_cupertino/cupertino_native_tabbar")

        let scaffoldFactory = NativeScaffoldFactory(messenger: registrar.messenger())
        registrar.register(
            scaffoldFactory, withId: "com.example.flutter_cupertino/cupertino_native_scaffold")

        let channel = FlutterMethodChannel(
            name: "com.example.flutter_cupertino/alert", binaryMessenger: registrar.messenger())
        let instance = FlutterCupertinoPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let progressFactory = NativeProgressFactory(messenger: registrar.messenger())
        registrar.register(
            progressFactory, withId: "com.example.flutter_cupertino/cupertino_native_progress")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "showAlert" {
            guard let args = call.arguments as? [String: Any],
                let title = args["title"] as? String,
                let actions = args["actions"] as? [[String: Any]]
            else {
                result(
                    FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
                return
            }
            let message = args["message"] as? String

            AlertManager.shared.show(
                title: title, message: message, actions: actions, result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}

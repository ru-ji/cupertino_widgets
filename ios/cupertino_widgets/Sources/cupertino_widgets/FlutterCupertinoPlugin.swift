import Flutter
import UIKit

public class FlutterCupertinoPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        // Register the method channel unconditionally so calls on old systems
        // get a descriptive error instead of a MissingPluginException.
        let channel = FlutterMethodChannel(
            name: "com.example.cupertino_widgets/alert", binaryMessenger: registrar.messenger())
        let instance = FlutterCupertinoPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // The native views are built on iOS 15+ SwiftUI/UIKit APIs. On older
        // systems register no platform views: the app still links and runs.
        guard #available(iOS 15.0, *) else { return }

        // Sheet events (bar actions, segment/search changes) flow back to
        // Dart over the main app's messenger. First registration wins: the
        // app engine registers at launch, before any body/sheet engine.
        if NativeSheetManager.shared.mainMessenger == nil {
            NativeSheetManager.shared.mainMessenger = registrar.messenger()
        }

        let menuFactory = NativeMenuFactory(messenger: registrar.messenger())
        registrar.register(
            menuFactory, withId: "com.example.cupertino_widgets/cupertino_native_menu")

        let buttonFactory = NativeButtonFactory(messenger: registrar.messenger())
        registrar.register(
            buttonFactory, withId: "com.example.cupertino_widgets/cupertino_native_button")

        let toggleFactory = NativeToggleFactory(messenger: registrar.messenger())
        registrar.register(
            toggleFactory, withId: "com.example.cupertino_widgets/cupertino_native_toggle")

        let segmentedFactory = NativeSegmentedControlFactory(messenger: registrar.messenger())
        registrar.register(
            segmentedFactory, withId: "com.example.cupertino_widgets/cupertino_native_segmented")

        let sliderFactory = NativeSliderFactory(messenger: registrar.messenger())
        registrar.register(
            sliderFactory, withId: "com.example.cupertino_widgets/cupertino_native_slider")

        let textFieldFactory = NativeTextFieldFactory(messenger: registrar.messenger())
        registrar.register(
            textFieldFactory, withId: "com.example.cupertino_widgets/cupertino_native_text_field")

        let tabBarFactory = NativeTabBarFactory(messenger: registrar.messenger())
        registrar.register(
            tabBarFactory, withId: "com.example.cupertino_widgets/cupertino_native_tabbar")

        let scaffoldFactory = NativeScaffoldFactory(messenger: registrar.messenger())
        registrar.register(
            scaffoldFactory, withId: "com.example.cupertino_widgets/cupertino_native_scaffold")

        let progressFactory = NativeProgressFactory(messenger: registrar.messenger())
        registrar.register(
            progressFactory, withId: "com.example.cupertino_widgets/cupertino_native_progress")

        let listFactory = NativeListFactory(messenger: registrar.messenger())
        registrar.register(
            listFactory, withId: "com.example.cupertino_widgets/cupertino_native_list")

        let liquidGlassFactory = NativeLiquidGlassFactory(messenger: registrar.messenger())
        registrar.register(
            liquidGlassFactory,
            withId: "com.example.cupertino_widgets/cupertino_native_liquid_glass")

        let datePickerFactory = NativeDatePickerFactory(messenger: registrar.messenger())
        registrar.register(
            datePickerFactory,
            withId: "com.example.cupertino_widgets/cupertino_native_date_picker")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "prewarmScaffold" {
            if #available(iOS 15.0, *) {
                let args = call.arguments as? [String: Any]
                NativeScaffoldView.prewarm(
                    routes: args?["routes"] as? [String] ?? [],
                    isDark: args?["isDark"] as? Bool ?? false)
            }
            result(nil)
            return
        }
        if call.method == "showSheet" {
            guard #available(iOS 15.0, *) else {
                result(
                    FlutterError(
                        code: "UNSUPPORTED_OS_VERSION",
                        message: "CupertinoNativeSheet requires iOS 15 or later",
                        details: nil))
                return
            }
            NativeSheetManager.shared.show(
                args: call.arguments as? [String: Any] ?? [:], result: result)
            return
        }
        if call.method == "dismissSheet" {
            if #available(iOS 15.0, *) {
                NativeSheetManager.shared.dismiss(result: result)
            } else {
                result(nil)
            }
            return
        }
        if call.method == "isLiquidGlassSupported" {
            if #available(iOS 26.0, *) {
                result(true)
            } else {
                result(false)
            }
            return
        }
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

            guard #available(iOS 15.0, *) else {
                result(
                    FlutterError(
                        code: "UNSUPPORTED_OS_VERSION",
                        message: "cupertino_widgets requires iOS 15 or later",
                        details: nil))
                return
            }
            AlertManager.shared.show(
                title: title, message: message, actions: actions, result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}

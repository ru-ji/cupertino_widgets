import Flutter
import UIKit

@available(iOS 15.0, *)
class AlertManager {
    static let shared = AlertManager()

    func show(
        title: String,
        message: String?,
        actions: [[String: Any]],
        isDark: Bool,
        result: @escaping FlutterResult
    ) {
        // Find the top-most view controller to present the alert
        guard let window = Self.keyWindow(), 
            let rootVC = window.rootViewController
        else {
            result(FlutterError(code: "NO_WINDOW", message: "No key window found", details: nil))
            return
        }

        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        // Follows the app's own (possibly forced) theme, not the device's
        // system appearance — same convention as every other native surface.
        alertController.overrideUserInterfaceStyle = isDark ? .dark : .light

        for (index, actionData) in actions.enumerated() {
            let title = actionData["title"] as? String ?? ""
            let isDestructive = actionData["isDestructive"] as? Bool ?? false
            let isCancel = actionData["isCancel"] as? Bool ?? false

            var style: UIAlertAction.Style = .default
            if isDestructive {
                style = .destructive
            } else if isCancel {
                style = .cancel
            }

            let action = UIAlertAction(title: title, style: style) { _ in
                result(index)
            }
            alertController.addAction(action)
        }

        // Ensure we present on the top-most controller
        DispatchQueue.main.async {
            let topController = self.getTopViewController(base: rootVC)
            topController?.present(alertController, animated: true, completion: nil)
        }
    }

    /// Scene-based key-window lookup (`UIApplication.windows` is deprecated
    /// since iOS 15). Prefers the key window of a foreground-active scene,
    /// falling back to any connected scene's key window.
    private static func keyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let ordered =
            scenes.filter { $0.activationState == .foregroundActive }
            + scenes.filter { $0.activationState != .foregroundActive }
        for scene in ordered {
            if let window = scene.windows.first(where: { $0.isKeyWindow }) {
                return window
            }
        }
        return ordered.first?.windows.first
    }

    private func getTopViewController(base: UIViewController?) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}

import Flutter
import UIKit

class AlertManager {
    static let shared = AlertManager()

    func show(
        title: String,
        message: String?,
        actions: [[String: Any]],
        result: @escaping FlutterResult
    ) {
        // Find the top-most view controller to present the alert
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
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

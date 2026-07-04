import Flutter
import SwiftUI
import UIKit

/// Base class for platform views that host a SwiftUI view via `UIHostingController`.
/// Owns the hosting-controller lifecycle, Auto Layout pinning, and intrinsic-size
/// calculation shared by every `Native*View` bridge class. Subclasses own their own
/// `FlutterMethodChannel`, method-call routing, and config decoding.
class NativeHostingView: NSObject, FlutterPlatformView {
    let _view = UIView()
    private(set) var hostingController: UIHostingController<AnyView>?

    func view() -> UIView {
        return _view
    }

    /// Creates (or replaces) the hosting controller with `content`, laid out by `configureConstraints`
    /// (defaults to pinning all 4 edges to `_view`, which is what most widgets want).
    func attach(
        _ content: AnyView,
        configureConstraints: (UIView, UIView) -> Void = { host, container in
            NSLayoutConstraint.activate([
                host.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                host.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                host.topAnchor.constraint(equalTo: container.topAnchor),
                host.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
        }
    ) {
        hostingController?.view.removeFromSuperview()

        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(host.view)
        configureConstraints(host.view, _view)
        hostingController = host
    }

    /// Replaces the currently hosted SwiftUI view's root without re-attaching.
    func update(_ content: AnyView) {
        hostingController?.rootView = content
    }

    /// Measures the hosted SwiftUI content's natural size, for `getIntrinsicSize` handlers.
    func intrinsicSize() -> [String: Double] {
        guard let host = hostingController else { return ["width": 0.0, "height": 0.0] }
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        let fittingSize = host.sizeThatFits(
            in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        return ["width": Double(fittingSize.width), "height": Double(fittingSize.height)]
    }
}

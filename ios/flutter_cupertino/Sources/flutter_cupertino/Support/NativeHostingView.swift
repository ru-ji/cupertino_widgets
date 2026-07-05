import Flutter
import SwiftUI
import UIKit

/// Base class for platform views that host a SwiftUI view via `UIHostingController`.
/// Owns the hosting-controller lifecycle, Auto Layout pinning, and intrinsic-size
/// calculation shared by every `Native*View` bridge class. Subclasses own their own
/// `FlutterMethodChannel`, method-call routing, and config decoding.
class NativeHostingView: NSObject, FlutterPlatformView {
    let _view = HostingContainerView()
    private(set) var hostingController: UIHostingController<AnyView>?

    func view() -> UIView {
        return _view
    }

    /// Creates (or replaces) the hosting controller with `content`, laid out by `configureConstraints`
    /// (defaults to pinning all 4 edges to `_view`, which is what most widgets want).
    ///
    /// `keyboardAvoidance` is off by default: SwiftUI's automatic keyboard
    /// avoidance would shift each control up inside its own (Flutter-sized)
    /// container when the keyboard appears, making embedded controls visibly
    /// slide over neighboring Flutter content. The scaffold opts back in,
    /// since it owns a full-screen hierarchy where avoidance is correct.
    func attach(
        _ content: AnyView,
        keyboardAvoidance: Bool = false,
        configureConstraints: (UIView, UIView) -> Void = { host, container in
            NSLayoutConstraint.activate([
                host.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                host.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                host.topAnchor.constraint(equalTo: container.topAnchor),
                host.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
        }
    ) {
        if let old = hostingController {
            old.willMove(toParent: nil)
            old.view.removeFromSuperview()
            old.removeFromParent()
        }

        let host = UIHostingController(rootView: content)
        if !keyboardAvoidance {
            if #available(iOS 16.4, *) {
                // Embedded controls are sized and positioned entirely by
                // Flutter, so no safe-area region may influence their layout:
                // .keyboard would shift content up inside the box when the
                // keyboard opens, and .container insets content away from the
                // screen edge when the box scrolls near it (content visibly
                // overflowing onto neighboring Flutter widgets).
                host.safeAreaRegions = []
            }
        }
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(host.view)
        configureConstraints(host.view, _view)
        hostingController = host
        // Keep the controller parented into the view-controller hierarchy for
        // as long as our container is in a window (see HostingContainerView).
        _view.hostedController = host
        _view.updateHostParenting()
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

/// Container view that keeps the hosted `UIHostingController` properly
/// parented as a child view controller of whatever view controller owns the
/// window it currently lives in (the FlutterViewController, in practice).
///
/// Without containment the hosting controller is "unparented": it never
/// receives appearance/containment callbacks, and when Flutter removes and
/// re-adds the platform view around route navigation the controller's layout
/// and safe-area state can come back corrupted (controls remeasure oversized
/// and overlap). Parenting on window attach — and unparenting on detach — is
/// the UIKit-sanctioned lifecycle for embedded hosting controllers.
final class HostingContainerView: UIView {
    weak var hostedController: UIHostingController<AnyView>?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateHostParenting()
    }

    func updateHostParenting() {
        guard let host = hostedController else { return }
        if window != nil {
            if host.parent == nil, let owner = owningViewController() {
                owner.addChild(host)
                host.didMove(toParent: owner)
            }
        } else if host.parent != nil {
            host.willMove(toParent: nil)
            host.removeFromParent()
        }
    }

    /// Nearest view controller up the responder chain.
    private func owningViewController() -> UIViewController? {
        var responder: UIResponder? = next
        while let current = responder {
            if let vc = current as? UIViewController { return vc }
            responder = current.next
        }
        return nil
    }
}

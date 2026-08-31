import Flutter
import SwiftUI
import UIKit

/// Base class for platform views that host a SwiftUI view via `UIHostingController`.
/// Owns the hosting-controller lifecycle, Auto Layout pinning, and intrinsic-size
/// calculation shared by every `Native*View` bridge class. Subclasses own their own
/// `FlutterMethodChannel`, method-call routing, and config decoding.
@available(iOS 15.0, *)
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
        if #available(iOS 16.0, *) {
            // Keep `host.view.intrinsicContentSize` in step with the SwiftUI
            // content. Without it a hosting controller's view does not
            // republish its size as the content settles, and the content
            // hugging / compression resistance that the hug-and-center
            // widgets (button, switch) size themselves with has nothing to
            // read — the host resolves to an ambiguous size while the SwiftUI
            // control, which is `fixedSize`, keeps drawing at its own. That is
            // how a switch ends up painting past its box and off the screen
            // edge. Harmless where the host's edges are pinned: a required
            // pin outranks an intrinsic size every time.
            host.sizingOptions = .intrinsicContentSize
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
    ///
    /// Measured against an unbounded proposal, which is the size SwiftUI gives
    /// a view left to itself. A control that does not expand — a button, a
    /// switch — answers with exactly the size UIKit draws it at, so the box
    /// Flutter builds around it matches the pixels and nothing has to be
    /// clipped or padded to fit.
    ///
    /// A view that *fills*, though — a text field, a labeled switch, a button
    /// with `expand` — answers an unbounded proposal with the proposal
    /// itself: `.greatestFiniteMagnitude` in both axes, a number Flutter would
    /// happily build a box out of. Those are re-measured against the width
    /// Flutter has already given this view and a compressed height, which is
    /// the size they will really be laid out at.
    ///
    /// A degenerate answer (either axis at zero, which happens when the view
    /// has not been laid out yet) is reported as zero on both axes: the Dart
    /// side ignores non-positive sizes and keeps its default until a later
    /// measurement lands, rather than sizing the box to a bad number.
    func intrinsicSize() -> [String: Double] {
        guard let host = hostingController else { return ["width": 0.0, "height": 0.0] }
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        var fitting = host.sizeThatFits(
            in: CGSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude))
        if !Self.isUsable(fitting), _view.bounds.width > 0 {
            fitting = host.sizeThatFits(in: CGSize(width: _view.bounds.width, height: 0))
        }
        guard Self.isUsable(fitting) else { return ["width": 0.0, "height": 0.0] }
        return ["width": Double(fitting.width), "height": Double(fitting.height)]
    }

    /// A measurement Flutter can size a box with: laid out (non-zero) and not
    /// the unbounded proposal handed straight back. No control here is
    /// anywhere near this tall or wide, so the bound only ever rejects the
    /// "I fill whatever you give me" answer.
    private static func isUsable(_ size: CGSize) -> Bool {
        let maxSensible: CGFloat = 100_000
        return size.width > 0 && size.height > 0
            && size.width < maxSensible && size.height < maxSensible
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
@available(iOS 15.0, *)
final class HostingContainerView: UIView {
    weak var hostedController: UIHostingController<AnyView>?

    /// Called after every (re)parenting pass. Containment changes make UIKit
    /// re-derive the hosted controller's layout margins, so subclass owners
    /// that force custom margins (the scaffold) re-assert them here.
    var onParentingChanged: (() -> Void)?

    /// Called on every layout pass of the container. UIKit recomputes the
    /// hosted hierarchy's margins during layout, so margin-forcing owners
    /// re-assert here too (must not trigger another layout).
    var onLayout: (() -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateHostParenting()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
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
        onParentingChanged?()
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

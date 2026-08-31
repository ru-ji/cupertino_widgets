import Flutter
import SwiftUI
import UIKit

@available(iOS 15.0, *)
class NativeScrollEdgeEffectFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeScrollEdgeEffectView(arguments: args)
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// **Probe.** The system's own scroll edge effect, hosted over Flutter content.
///
/// `UIScrollEdgeEffect` is a property of a scroll view, not a free-standing
/// effect: there is no API that says "draw the edge effect on this rectangle".
/// So this hosts a real SwiftUI `ScrollView` whose content is transparent and
/// parked mid-scroll, purely so the effect is in its active state, and lets
/// whatever Flutter draws behind the platform view be its backdrop.
///
/// The open question this exists to answer: does the effect sample what is
/// *behind* the hosting view — the way `glassEffect` demonstrably refracts
/// Flutter content behind our glass container — or only the (empty) content of
/// the scroll view it belongs to? If the former, the system's adaptive tint
/// works over Flutter pages. If the latter, it paints nothing and a Flutter
/// page can never have more than a recreation.
@available(iOS 15.0, *)
class NativeScrollEdgeEffectView: NativeHostingView {
    init(arguments args: Any?) {
        super.init()
        let map = args as? [String: Any] ?? [:]
        attach(
            AnyView(
                ScrollEdgeEffectProbe(
                    style: map["style"] as? String ?? "soft",
                    inset: CGFloat(map["inset"] as? Double ?? 100)
                )))
    }
}

@available(iOS 15.0, *)
struct ScrollEdgeEffectProbe: View {
    let style: String
    /// Height of the region the effect draws in — the safe area a bar would
    /// have inset, since that is what the effect is drawn against.
    let inset: CGFloat

    var body: some View {
        if #available(iOS 26.0, *) {
            ScrollView {
                // Transparent, and taller than the view: the effect only shows
                // where content passes under the inset area, so there has to
                // be content — even content that draws nothing.
                Color.clear.frame(height: 4000)
            }
            // Parked mid-content, so the effect stays in its "content is
            // underneath me" state without anyone scrolling this view.
            .defaultScrollAnchor(.center)
            // The view must not eat the page's gestures: Flutter owns the
            // scroll, this is only here to be looked at.
            .scrollDisabled(true)
            .safeAreaInset(edge: .top) { Color.clear.frame(height: inset) }
            .scrollEdgeEffectStyle(style == "hard" ? .hard : .soft, for: .top)
            .allowsHitTesting(false)
        } else {
            Color.clear
        }
    }
}

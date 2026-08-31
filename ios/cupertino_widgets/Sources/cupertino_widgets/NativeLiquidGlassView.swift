import Flutter
import SwiftUI
import UIKit

@available(iOS 15.0, *)
class NativeLiquidGlassFactory: NSObject, FlutterPlatformViewFactory {
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
        return NativeLiquidGlassView(
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

/// Platform view exposing the iOS 26 Liquid Glass material as a backdrop that
/// Flutter content is composited on top of. On iOS 15–25 it renders an
/// `ultraThinMaterial` approximation so layouts don't break, but the real
/// refractive effect is 26-only (see `isLiquidGlassSupported` on the plugin
/// channel for feature-gating from Dart).
@available(iOS 15.0, *)
class NativeLiquidGlassView: NativeHostingView {
    private var channel: FlutterMethodChannel?
    /// Engine hosting the `route` body, when the container has one. Spawned
    /// from the scaffold's shared group so it costs a warm spawn, not a cold
    /// boot, and parked (not destroyed) if the same route comes back.
    private var bodyEngine: FlutterEngine?
    private var bodyRoute: String?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        super.init()

        channel = FlutterMethodChannel(
            name: "cupertino_widgets/liquid_glass_\(viewId)", binaryMessenger: messenger)
        channel?.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handle(call, result: result)
        })

        if let argsMap = args as? [String: Any],
            let config = decodeConfig(GlassConfig.self, from: argsMap)
        {
            setupSwiftUI(with: config)
        }
    }

    /// Attaches the glass the way `NativeButtonView` attaches the button, and
    /// on the same flag.
    ///
    /// `expand` is what Dart sends when a Flutter child or an explicit size —
    /// not a native icon — is what gives this container its size. The button
    /// hugs its content because SwiftUI can see that content and measure it; a
    /// glass container's content is the Flutter child composited on top, which
    /// the native side never sees.
    private func setupSwiftUI(with config: GlassConfig) {
        let content = AnyView(
            AdaptiveLiquidGlassView(config: config, engine: engine(for: config)) {
                [weak self] in
                self?.channel?.invokeMethod("pressed", arguments: nil)
            })
        guard config.expand != true else {
            attach(content)
            return
        }
        // No Flutter child and no explicit size: the glass is measured like a
        // button, hugging the icon and the material around it, and
        // `getIntrinsicSize` hands that back so Flutter can build the box.
        attach(content) { host, container in
            host.setContentHuggingPriority(.required, for: .horizontal)
            host.setContentHuggingPriority(.required, for: .vertical)
            NSLayoutConstraint.activate([
                host.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                host.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                host.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor),
                host.heightAnchor.constraint(lessThanOrEqualTo: container.heightAnchor),
            ])
        }
    }

    /// The engine for `config.route`, spawned on first use and reused across
    /// updates. Registering this plugin on it is what lets the hosted body use
    /// package widgets of its own.
    private func engine(for config: GlassConfig) -> FlutterEngine? {
        guard let route = config.route else { return nil }
        if let bodyEngine, bodyRoute == route { return bodyEngine }
        bodyEngine?.viewController = nil
        let engine =
            NativeScaffoldView.takePooledEngine(route: route)
            ?? NativeScaffoldView.sharedEngineGroup.makeEngine(
                withEntrypoint: nil, libraryURI: nil,
                initialRoute: "cn-scaffold://\(route)")
        if let registrar = engine.registrar(forPlugin: "FlutterCupertinoPlugin") {
            FlutterCupertinoPlugin.register(with: registrar)
        }
        bodyEngine = engine
        bodyRoute = route
        return engine
    }

    deinit {
        bodyEngine?.viewController = nil
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getIntrinsicSize":
            result(intrinsicSize())
        case "updateGlass":
            if let argsMap = call.arguments as? [String: Any],
                let config = decodeConfig(GlassConfig.self, from: argsMap)
            {
                setupSwiftUI(with: config)
                result(nil)
            } else {
                result(
                    FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

@available(iOS 15.0, *)
struct AdaptiveLiquidGlassView: View {
    let config: GlassConfig
    /// Engine rendering the `route` body, when there is one.
    let engine: FlutterEngine?
    let onPressed: () -> Void

    private var expand: Bool { config.expand ?? false }
    private var tint: Color? { config.tint.map { Color(argb: $0) } }

    var body: some View {
        if #available(iOS 26.0, *) {
            // The shape Apple's "Applying Liquid Glass to custom views" asks
            // for, in its order: content, then the padding, then the frame,
            // then `glassEffect` last — it captures what it wraps and hands
            // that to the container to render, so nothing that affects
            // appearance may come after it.
            //
            //     Color.white.opacity(0.001)
            //         .frame(width: 80, height: 80)
            //         .glassEffect(.regular.interactive(), in: Circle())
            //
            GlassEffectContainer {
                content
                    .glassEffect(glass, in: glassShape)
                    .simultaneousGesture(
                        TapGesture().onEnded { if config.pressable == true { onPressed() } })
            }
        } else {
            // Pre-26 approximation: a system material with an optional tint
            // wash. No refraction — Liquid Glass itself is iOS 26+.
            fallbackClipped
                .overlay(iconView)
                .applyGlassExpand(expand)
                .simultaneousGesture(
                    TapGesture().onEnded { if config.pressable == true { onPressed() } })
        }
    }

    /// What the glass is painted around: a native icon when there is one, and
    /// otherwise Apple's own placeholder — invisible to the eye, solid to
    /// touches. It has to be *something*: `EmptyView` is erased from the
    /// hierarchy (frame and all, so the glass gets a 0×0 shape and paints
    /// nothing) and `Color.clear` has no substance for `.interactive()` to
    /// track, which is a container that renders but never responds.
    @ViewBuilder
    private var base: some View {
        if let engine, #available(iOS 16.0, *) {
            // The Flutter body as a SwiftUI view — so `glassEffect` captures
            // it the way it captures a `Text` or an `Image`, and the content
            // ends up *in* the material instead of composited over it. This
            // is the only arrangement in which Flutter content is refracted
            // correctly rather than lensed at the glass edges.
            FlutterContentView(engine: engine)
        } else if let icon = config.icon {
            IconView(icon: icon)
        } else {
            // No content of its own: Apple's placeholder, invisible to the eye
            // but solid to touches, so `.interactive()` has something to
            // track. `EmptyView` is erased from the hierarchy (the glass gets
            // a 0x0 shape and paints nothing) and `Color.clear` has no
            // substance for the interaction to hold on to.
            Color.white.opacity(0.001)
        }
    }

    /// Sized, inset, ready for the material. An explicit `width`/`height` from
    /// Dart wins; otherwise the glass either fills the box Flutter built
    /// (`expand`) or hugs the icon so `getIntrinsicSize` can measure it.
    @ViewBuilder
    private var content: some View {
        // Padding before the frame, not after: an inset applied last would
        // push the material *outward* past a size Flutter already reserved,
        // and on an expanding container it would shrink the glass away from
        // the box it is meant to fill. Inside, it does what it is for —
        // spacing a native icon off the glass edge, so the container measures
        // like a control instead of like a glyph.
        base
            .padding(insets)
            .applySize(width: config.width, height: config.height, expand: expand)
    }

    private var insets: EdgeInsets {
        EdgeInsets(
            top: CGFloat(config.paddingTop ?? 0),
            leading: CGFloat(config.paddingLeft ?? 0),
            bottom: CGFloat(config.paddingBottom ?? 0),
            trailing: CGFloat(config.paddingRight ?? 0))
    }

    /// The icon alone, for the pre-26 overlay.
    @ViewBuilder
    private var iconView: some View {
        if let icon = config.icon { IconView(icon: icon).padding(insets) }
    }

    @ViewBuilder
    private var fallbackClipped: some View {
        switch config.shape {
        case "capsule": fallbackMaterial.clipShape(Capsule())
        case "circle": fallbackMaterial.clipShape(Circle())
        default:
            fallbackMaterial.clipShape(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    private var fallbackMaterial: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay((tint ?? Color.clear).opacity(0.18))
    }

    private var cornerRadius: CGFloat { CGFloat(config.cornerRadius ?? 26) }

    @available(iOS 26.0, *)
    private var glass: Glass {
        var glass: Glass = config.variant == "clear" ? .clear : .regular
        if let tint { glass = glass.tint(tint) }
        if config.interactive == true { glass = glass.interactive() }
        return glass
    }

    @available(iOS 16.0, *)
    private var glassShape: AnyShape {
        switch config.shape {
        case "capsule":
            return AnyShape(Capsule())
        case "circle":
            return AnyShape(Circle())
        default:
            return AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

@available(iOS 15.0, *)
extension View {
    /// `.frame(width:height:)` when Dart sent a size, the full box when
    /// Flutter owns it, and the view's own size otherwise (an icon-only
    /// container, which is measured and reported back to Flutter).
    @ViewBuilder
    func applySize(width: Double?, height: Double?, expand: Bool) -> some View {
        if width != nil || height != nil {
            self.frame(width: width.map { CGFloat($0) }, height: height.map { CGFloat($0) })
        } else if expand {
            self.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            self
        }
    }

    /// Stretches the pre-26 material across the box Flutter built, in both
    /// axes. (On iOS 26 the same job is done by `content`.)
    @ViewBuilder
    func applyGlassExpand(_ expand: Bool) -> some View {
        if expand {
            self.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            self
        }
    }
}

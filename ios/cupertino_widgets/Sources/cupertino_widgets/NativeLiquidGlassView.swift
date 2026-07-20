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

        if let argsMap = args as? [String: Any] {
            attach(AnyView(makeContent(with: argsMap)))
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "updateGlass", let args = call.arguments as? [String: Any] {
            update(AnyView(makeContent(with: args)))
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func makeContent(with args: [String: Any]) -> some View {
        AdaptiveLiquidGlassView(
            shape: args["shape"] as? String ?? "roundedRect",
            cornerRadius: CGFloat(args["cornerRadius"] as? Double ?? 26),
            variant: args["variant"] as? String ?? "regular",
            tint: (args["tint"] as? Int).map { Color(argb: $0) },
            interactive: args["interactive"] as? Bool ?? false,
            pressable: args["pressable"] as? Bool ?? false,
            icon: (args["icon"] as? [String: Any]).flatMap {
                decodeConfig(IconConfig.self, from: $0)
            },
            onPressed: { [weak self] in
                self?.channel?.invokeMethod("pressed", arguments: nil)
            }
        )
    }
}

@available(iOS 15.0, *)
struct AdaptiveLiquidGlassView: View {
    let shape: String
    let cornerRadius: CGFloat
    let variant: String  // "regular" | "clear"
    let tint: Color?
    let interactive: Bool
    let pressable: Bool
    let icon: IconConfig?
    let onPressed: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            // Straight from Apple's "Applying Liquid Glass to custom views":
            // a GlassEffectContainer hosting `glassEffect(_:in:)`, with
            // `.interactive()` supplying the system touch response (shimmer /
            // stretch / bounce). The icon is glassEffect CONTENT so it
            // renders crisply above the material. No custom press gestures:
            // a high-priority gesture would starve the glass's own
            // interaction tracking, so taps use `simultaneousGesture`.
            GlassEffectContainer {
                ZStack {
                    // Interactive glass ignores fully transparent content —
                    // `.glassEffect(.interactive())` on `Color.clear` never
                    // reacts to touch. A near-invisible fill keeps the glass
                    // alive without visibly tinting it.
                    Color.white.opacity(0.02)
                    iconView
                }
                .glassEffect(glass, in: glassShape)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture().onEnded { if pressable { onPressed() } })
            }
        } else {
            // Pre-26 approximation: a system material with an optional tint
            // wash. No refraction — Liquid Glass itself is iOS 26+.
            fallbackClipped
                .overlay(iconView)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture().onEnded { if pressable { onPressed() } })
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon { IconView(icon: icon) }
    }

    @ViewBuilder
    private var fallbackClipped: some View {
        switch shape {
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

    @available(iOS 26.0, *)
    private var glass: Glass {
        var glass: Glass = variant == "clear" ? .clear : .regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return glass
    }

    @available(iOS 16.0, *)
    private var glassShape: AnyShape {
        switch shape {
        case "capsule":
            return AnyShape(Capsule())
        case "circle":
            return AnyShape(Circle())
        default:
            return AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}


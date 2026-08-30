import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'internal/native_platform_view_mixin.dart';
import 'models/cupertino_native_icon.dart';

/// The shape of a [CupertinoNativeGlassContainer].
enum CupertinoGlassShape { capsule, circle, roundedRect }

/// Which Liquid Glass material variant to render (SwiftUI `Glass` /
/// `UIGlassEffect.Style`): [regular] is the standard adaptive glass,
/// [clear] is the more transparent variant for media-rich backdrops.
/// Ignored below iOS 26, where the material fallback has no variants.
enum CupertinoGlassVariant { regular, clear }

/// Liquid Glass settings for a control that renders *on* glass rather than
/// being a glass container itself — currently [CupertinoNativeTextField.glass].
///
/// Passing one enables the effect; leaving it null renders the plain control.
/// The field names match [CupertinoNativeGlassContainer]'s, so the same
/// vocabulary describes glass wherever it appears.
///
/// ```dart
/// CupertinoNativeTextField(
///   placeholder: 'Search',
///   glass: CupertinoGlass(cornerRadius: 22),
/// )
/// ```
class CupertinoGlass {
  /// Corner radius of the glass shape (continuous corners).
  final double cornerRadius;

  /// Standard adaptive glass, or the more transparent clear variant (iOS 26).
  final CupertinoGlassVariant variant;

  /// Whether the glass reacts to touches with the system shimmer (iOS 26).
  final bool interactive;

  /// Optional tint mixed into the glass material.
  final Color? tint;

  const CupertinoGlass({
    this.cornerRadius = 16,
    this.variant = CupertinoGlassVariant.regular,
    this.interactive = true,
    this.tint,
  });

  @override
  bool operator ==(Object other) =>
      other is CupertinoGlass &&
      other.cornerRadius == cornerRadius &&
      other.variant == variant &&
      other.interactive == interactive &&
      other.tint == tint;

  @override
  int get hashCode => Object.hash(cornerRadius, variant, interactive, tint);
}

/// A container backed by the iOS 26 **Liquid Glass** material
/// (SwiftUI's `.glassEffect`). The glass is a real native view that refracts
/// whatever Flutter content is rendered behind it; [child] is ordinary Flutter
/// content composited on top, so it stays fully interactive.
///
/// ```dart
/// CupertinoNativeGlassContainer(
///   shape: CupertinoGlassShape.capsule,
///   padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
///   child: Text('Now Playing'),
/// )
/// ```
///
/// **Availability:** the refractive effect requires iOS 26+. On iOS 15–25 the
/// native side renders a static `ultraThinMaterial` approximation so layouts
/// don't break; on other platforms a translucent [DecoratedBox] is used. Query
/// [isSupported] to branch your UI on the real effect.
class CupertinoNativeGlassContainer extends StatefulWidget {
  const CupertinoNativeGlassContainer({
    super.key,
    this.child,
    this.shape = CupertinoGlassShape.roundedRect,
    this.cornerRadius = 26,
    this.variant = CupertinoGlassVariant.regular,
    this.tint,
    this.interactive = false,
    this.onPressed,
    this.icon,
    this.childInteractive = false,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
  });

  /// Flutter content drawn on top of the glass. The glass sizes itself to the
  /// child (plus [padding]) unless [width]/[height] are given.
  final Widget? child;

  final CupertinoGlassShape shape;

  /// Corner radius for [CupertinoGlassShape.roundedRect]
  /// (continuous corners, default 26 to match iOS 26 cards).
  final double cornerRadius;

  /// Glass material variant — regular (default) or the more transparent
  /// clear glass (iOS 26).
  final CupertinoGlassVariant variant;

  /// Optional tint mixed into the glass material.
  final Color? tint;

  /// When true the glass reacts to touches with the system shimmer (iOS 26).
  final bool interactive;

  /// Called when the glass is tapped (native tap gesture on the glass
  /// surface). Set this to use the container as a liquid-glass button —
  /// combine with [interactive] for the touch shimmer.
  final VoidCallback? onPressed;

  /// SF Symbol (or Flutter glyph) rendered natively, centered in the glass —
  /// the easy way to make an icon-only glass button without a Flutter child.
  final CupertinoNativeIcon? icon;

  /// Whether [child] participates in hit testing. Defaults to false so every
  /// touch falls through to the glass itself ([interactive] shimmer,
  /// [onPressed]); set true when the child contains buttons, sliders or other
  /// widgets that must receive their own touches.
  final bool childInteractive;

  /// Inset between the glass bounds and [child].
  final EdgeInsetsGeometry padding;

  final double? width;
  final double? height;

  /// Whether the running device renders real Liquid Glass (iOS 26+).
  static Future<bool> get isSupported async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    const channel = MethodChannel('com.example.cupertino_widgets/alert');
    try {
      return await channel.invokeMethod<bool>('isLiquidGlassSupported') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  State<CupertinoNativeGlassContainer> createState() =>
      _CupertinoNativeGlassContainerState();
}

class _CupertinoNativeGlassContainerState
    extends State<CupertinoNativeGlassContainer>
    with NativePlatformViewStateMixin {
  Map<String, dynamic> _toMap() {
    return {
      'shape': widget.shape.name,
      'cornerRadius': widget.cornerRadius,
      'variant': widget.variant.name,
      'tint': widget.tint?.toARGB32(),
      'interactive': widget.interactive,
      'pressable': widget.onPressed != null,
      'icon': widget.icon?.toMap(),
    };
  }

  @override
  void didUpdateWidget(covariant CupertinoNativeGlassContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shape != widget.shape ||
        oldWidget.cornerRadius != widget.cornerRadius ||
        oldWidget.variant != widget.variant ||
        oldWidget.tint != widget.tint ||
        oldWidget.interactive != widget.interactive ||
        oldWidget.icon != widget.icon ||
        (oldWidget.onPressed != null) != (widget.onPressed != null)) {
      updateNativeView('updateGlass', _toMap(), refreshIntrinsicSize: false);
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'pressed') {
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Touches must reach the native view immediately for the interactive
      // shimmer / tap gesture — inside scrollables Flutter's gesture arena
      // would otherwise delay and cancel them.
      final wantsTouches = widget.interactive || widget.onPressed != null;
      content = Stack(
        // Center the child when the box is forced bigger than it (e.g. an
        // explicit height with intrinsic width).
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: UiKitView(
              viewType:
                  'com.example.cupertino_widgets/cupertino_native_liquid_glass',
              layoutDirection: TextDirection.ltr,
              creationParams: _toMap(),
              creationParamsCodec: const StandardMessageCodec(),
              hitTestBehavior: wantsTouches
                  ? PlatformViewHitTestBehavior.opaque
                  : PlatformViewHitTestBehavior.transparent,
              gestureRecognizers: wantsTouches
                  ? {
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    }
                  : const {},
              onPlatformViewCreated: (id) => setUpChannel(
                id,
                'cupertino_widgets/liquid_glass_$id',
                onMethodCall: _handleMethodCall,
              ),
            ),
          ),
          IgnorePointer(
            ignoring: !widget.childInteractive,
            child: Padding(
              padding: widget.padding,
              child: widget.child ?? const SizedBox.shrink(),
            ),
          ),
        ],
      );
    } else {
      // Non-iOS fallback: a translucent rounded box.
      Widget box = DecoratedBox(
        decoration: BoxDecoration(
          color: (widget.tint ?? const Color(0xFF787880)).withValues(
            alpha: 0.2,
          ),
          borderRadius: widget.shape == CupertinoGlassShape.circle
              ? null
              : BorderRadius.circular(
                  widget.shape == CupertinoGlassShape.capsule
                      ? 999
                      : widget.cornerRadius,
                ),
          shape: widget.shape == CupertinoGlassShape.circle
              ? BoxShape.circle
              : BoxShape.rectangle,
        ),
        child: Padding(
          padding: widget.padding,
          child: widget.child ?? const SizedBox.shrink(),
        ),
      );
      if (widget.onPressed != null) {
        box = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: box,
        );
      }
      content = box;
    }

    if (widget.width != null || widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: content,
      );
    }
    return content;
  }
}

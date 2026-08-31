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
    this.route,
  });

  /// Flutter content drawn on top of the glass. The glass sizes itself to the
  /// child (plus [padding]) unless [width]/[height] are given.
  ///
  /// This content is composited *over* the native view, so the glass treats
  /// it as backdrop and refracts it at the edges — visible with the clear
  /// variant, where nothing veils it. Use [route] for content that belongs
  /// inside the glass instead.
  final Widget? child;

  /// A body route whose Flutter content is hosted *inside* the glass.
  ///
  /// The container spawns a Flutter engine on this route and applies
  /// `glassEffect` to the hosted view itself — the SwiftUI arrangement Apple
  /// documents (`content.glassEffect(...)`), rather than a native surface
  /// with Flutter stacked over it. The content is then real glass content:
  /// drawn above the material, crisp, and never lensed at the edges.
  ///
  /// The route is registered exactly like a [CupertinoNativeScaffold] body —
  /// `CupertinoNativeScaffold.maybeRun({'glass_label': () => ...})` in
  /// `main()`. It runs in its own isolate, so it cannot read the surrounding
  /// widget tree's state; talk to it over a channel, as scaffold bodies do.
  final String? route;

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

  /// Explicit size. Left null the glass finds its own, in this order: a
  /// [child] sizes it (plus [padding]); failing that a native [icon] does,
  /// measured by SwiftUI; and with neither it fills the space offered, the way
  /// a `Container` with no child does. An empty glass in an unbounded space
  /// has nothing to fill and falls back to a standard 44pt control, so it is
  /// visible rather than collapsed — pass a size to mean anything else.
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
      // Sized and inset natively too, not just boxed by Flutter: the glass
      // material is painted around the SwiftUI content, so a frame Flutter
      // knows about and SwiftUI doesn't paints the wrong shape.
      'width': widget.width,
      'height': widget.height,
      'paddingLeft': _padding.left,
      'paddingTop': _padding.top,
      'paddingRight': _padding.right,
      'paddingBottom': _padding.bottom,
      'route': widget.route,
      'expand': !_hugsContent,
    };
  }

  /// [padding] resolved to concrete insets, for the native side.
  ///
  /// A native icon left un-inset measures as the glyph — ~20pt for a 17pt
  /// symbol — and Flutter would build a 20pt box of glass around it. A
  /// toolbar draws a 44pt target around the same glyph, and 12 is that
  /// difference; it stands in only where the caller said nothing.
  EdgeInsets get _padding {
    final padding = widget.padding.resolve(TextDirection.ltr);
    final bare =
        widget.icon != null && _hugsContent && padding == EdgeInsets.zero;
    return bare ? const EdgeInsets.all(12) : padding;
  }

  /// Whether a native [icon] is the only thing sizing this container — the one
  /// case where the glass hugs its own content, exactly as the button does
  /// without `expand`. A Flutter child, an explicit size, or nothing at all
  /// means the glass fills the box Flutter builds instead; the native side has
  /// no way to see a Flutter child, so hugging one paints a glass of no size.
  bool get _hugsContent =>
      (widget.icon != null || widget.route != null) &&
      widget.child == null &&
      widget.width == null &&
      widget.height == null;

  /// Content the native side can measure — a symbol or a hosted body.
  bool get _hasNativeContent => widget.icon != null || widget.route != null;

  @override
  void didUpdateWidget(covariant CupertinoNativeGlassContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shape != widget.shape ||
        oldWidget.cornerRadius != widget.cornerRadius ||
        oldWidget.variant != widget.variant ||
        oldWidget.tint != widget.tint ||
        oldWidget.interactive != widget.interactive ||
        oldWidget.icon != widget.icon ||
        oldWidget.route != widget.route ||
        oldWidget.padding != widget.padding ||
        (oldWidget.child == null) != (widget.child == null) ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        (oldWidget.onPressed != null) != (widget.onPressed != null)) {
      updateNativeView('updateGlass', _toMap());
    }
  }

  Future<void> _onPlatformViewCreated(int id) async {
    setUpChannel(
      id,
      'cupertino_widgets/liquid_glass_$id',
      onMethodCall: _handleMethodCall,
    );
    // Only a native [icon] gives the hosted view something to measure. With a
    // Flutter child, or with nothing, SwiftUI has no content and answers zero
    // — six retried round trips for an answer this widget would discard.
    if (_hugsContent) requestIntrinsicSize();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'pressed') {
      widget.onPressed?.call();
    }
  }

  /// The size a glass container falls back to when it has none of its own: the
  /// standard iOS touch target, which is also what a glass toolbar button
  /// measures. Used until the native measurement lands, and for good where
  /// there is nothing at all to measure.
  static const double _defaultExtent = 44;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Touches must reach the native view immediately for the interactive
      // shimmer / tap gesture — inside scrollables Flutter's gesture arena
      // would otherwise delay and cancel them.
      final wantsTouches = widget.interactive || widget.onPressed != null;
      final glass = UiKitView(
        viewType: 'com.example.cupertino_widgets/cupertino_native_liquid_glass',
        layoutDirection: TextDirection.ltr,
        creationParams: _toMap(),
        creationParamsCodec: const StandardMessageCodec(),
        hitTestBehavior: wantsTouches
            ? PlatformViewHitTestBehavior.opaque
            : PlatformViewHitTestBehavior.transparent,
        gestureRecognizers: wantsTouches
            ? {
                Factory<OneSequenceGestureRecognizer>(
                  EagerGestureRecognizer.new,
                ),
              }
            : const {},
        onPlatformViewCreated: _onPlatformViewCreated,
      );
      final child = widget.child;
      content = child == null
          ? glass
          : Stack(
              // Center the child when the box is forced bigger than it (e.g. an
              // explicit height with intrinsic width).
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: glass),
                IgnorePointer(
                  ignoring: !widget.childInteractive,
                  child: Padding(padding: widget.padding, child: child),
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

    // Four ways to a size, in order of authority.
    //
    // 1. What the caller asked for.
    if (widget.width != null || widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: content,
      );
    }
    // 2. A Flutter [child]: the glass wraps it, plus [padding] — the stack
    //    already sizes to it.
    if (widget.child != null) return content;
    // 3. A native [icon] and nothing else: SwiftUI measured the glyph and the
    //    material around it, so take that — the same `getIntrinsicSize` round
    //    trip the button makes, with the same standing default until it lands.
    if (_hasNativeContent) {
      return SizedBox(
        width: intrinsicWidth ?? _defaultExtent,
        height: intrinsicHeight ?? _defaultExtent,
        child: content,
      );
    }
    // 4. Empty. Fill the space offered, the way a `Container` with no child
    //    does. Where the space is unbounded there is nothing to fill, and the
    //    zero this used to limit to is why an empty glass never appeared: a box
    //    of no height paints no material. It falls back to a standard control
    //    instead — still a number nobody asked for, but a visible one.
    return LimitedBox(
      maxWidth: _defaultExtent,
      maxHeight: _defaultExtent,
      child: content,
    );
  }
}

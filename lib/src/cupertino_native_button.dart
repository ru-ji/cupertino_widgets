import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'internal/native_platform_view_mixin.dart';
import 'models/cupertino_native_button_style.dart';
import 'models/cupertino_native_button_extra_options.dart';
import 'models/cupertino_native_icon.dart';

class CupertinoNativeButton extends StatefulWidget {
  final String title;

  /// The button's icon. Accepts an SF Symbol ([CupertinoNativeIcon.symbol] /
  /// [CupertinoNativeIcon.named]) or a Flutter [IconData]
  /// ([CupertinoNativeIcon.flutter]). Takes precedence over [systemImage].
  final CupertinoNativeIcon? icon;

  /// Convenience for a raw SF Symbol name. Ignored when [icon] is set. Prefer
  /// [icon] for typed symbols or Flutter icons.
  final String? systemImage;
  final CupertinoNativeButtonStyle style;
  final CupertinoNativeControlSize controlSize;
  final CupertinoNativeButtonBorderShape borderShape;
  final CupertinoNativeButtonLabelStyle labelStyle;
  final bool expand;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final Color? color;
  final TextStyle? textStyle;

  const CupertinoNativeButton({
    super.key,
    required this.title,
    this.icon,
    this.systemImage,
    this.style = CupertinoNativeButtonStyle.automatic,
    this.controlSize = CupertinoNativeControlSize.regular,
    this.borderShape = CupertinoNativeButtonBorderShape.automatic,
    this.labelStyle = CupertinoNativeButtonLabelStyle.titleAndIcon,
    this.expand = false,
    this.onPressed,
    this.width,
    this.height,
    this.color,
    this.textStyle,
  });

  @override
  State<CupertinoNativeButton> createState() => _CupertinoNativeButtonState();
}

class _CupertinoNativeButtonState extends State<CupertinoNativeButton>
    with NativePlatformViewStateMixin {
  /// The icon actually sent to native: [CupertinoNativeButton.icon] wins,
  /// falling back to [CupertinoNativeButton.systemImage] as a raw SF Symbol.
  CupertinoNativeIcon? get _effectiveIcon =>
      widget.icon ??
      (widget.systemImage != null
          ? CupertinoNativeIcon.named(widget.systemImage!)
          : null);

  @override
  void didUpdateWidget(covariant CupertinoNativeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.icon != widget.icon ||
        oldWidget.systemImage != widget.systemImage ||
        oldWidget.style != widget.style ||
        oldWidget.controlSize != widget.controlSize ||
        oldWidget.borderShape != widget.borderShape ||
        oldWidget.labelStyle != widget.labelStyle ||
        oldWidget.expand != widget.expand ||
        oldWidget.color != widget.color ||
        oldWidget.textStyle != widget.textStyle) {
      updateNativeView('updateButton', _toMap());
    }
  }

  Map<String, dynamic> _toMap() {
    return {
      'title': widget.title,
      'icon': _effectiveIcon?.toMap(),
      'style': widget.style.name,
      'controlSize': widget.controlSize.name,
      'borderShape': widget.borderShape.name,
      'labelStyle': widget.labelStyle.name,
      'expand': widget.expand,
      'color': widget.color?.toARGB32(),
      'fontSize': widget.textStyle?.fontSize,
      'fontWeight': widget.textStyle?.fontWeight?.index,
      'textColor': widget.textStyle?.color?.toARGB32(),
    };
  }

  Future<void> _onPlatformViewCreated(int id) async {
    setUpChannel(
      id,
      'flutter_cupertino/button_$id',
      onMethodCall: _handleMethodCall,
    );
    // Request intrinsic size after a short delay to let the view settle
    await Future.delayed(const Duration(milliseconds: 50));
    requestIntrinsicSize();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onPressed') {
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final platformView = UiKitView(
        viewType: 'com.example.flutter_cupertino/cupertino_native_button',
        layoutDirection: TextDirection.ltr,
        creationParams: _toMap(),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );

      // If explicit width/height provided, use them directly
      if (widget.width != null || widget.height != null) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: platformView,
        );
      }

      // Handle expand: true
      if (widget.expand) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Use actual available width from constraints
            final width = constraints.maxWidth.isInfinite
                ? 200.0
                : constraints.maxWidth;
            return SizedBox(
              width: width,
              height: intrinsicHeight ?? 34,
              child: platformView,
            );
          },
        );
      }

      // Use intrinsic size from native view, with defaults until size is received
      // Default: 80x34 (reasonable button size)
      return SizedBox(
        width: intrinsicWidth ?? 80,
        height: intrinsicHeight ?? 34,
        child: platformView,
      );
    }

    // Fallback for non-iOS
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFF007AFF),
        child: Text(
          widget.title,
          style: const TextStyle(color: Color(0xFFFFFFFF)),
        ),
      ),
    );
  }
}

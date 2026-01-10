import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'models/cupertino_native_button_style.dart';
import 'models/cupertino_native_button_extra_options.dart';

class CupertinoNativeButton extends StatefulWidget {
  final String title;
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

class _CupertinoNativeButtonState extends State<CupertinoNativeButton> {
  MethodChannel? _channel;
  double? _intrinsicWidth;
  double? _intrinsicHeight;

  @override
  void didUpdateWidget(covariant CupertinoNativeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.systemImage != widget.systemImage ||
        oldWidget.style != widget.style ||
        oldWidget.controlSize != widget.controlSize ||
        oldWidget.borderShape != widget.borderShape ||
        oldWidget.labelStyle != widget.labelStyle ||
        oldWidget.expand != widget.expand ||
        oldWidget.color != widget.color ||
        oldWidget.textStyle != widget.textStyle) {
      _updateButton();
    }
  }

  void _updateButton() {
    _channel?.invokeMethod('updateButton', _toMap()).then((_) {
      // Request new intrinsic size after update
      _requestIntrinsicSize();
    });
  }

  Future<void> _requestIntrinsicSize() async {
    if (_channel == null) return;
    try {
      final result = await _channel!.invokeMethod<Map>('getIntrinsicSize');
      if (result != null && mounted) {
        final w = (result['width'] as num?)?.toDouble();
        final h = (result['height'] as num?)?.toDouble();
        if (w != null && h != null && w > 0 && h > 0) {
          setState(() {
            _intrinsicWidth = w;
            _intrinsicHeight = h;
          });
        }
      }
    } catch (e) {
      // Ignore errors - view may not be ready yet
    }
  }

  Map<String, dynamic> _toMap() {
    return {
      'title': widget.title,
      'systemImage': widget.systemImage,
      'style': widget.style.name,
      'controlSize': widget.controlSize.name,
      'borderShape': widget.borderShape.name,
      'labelStyle': widget.labelStyle.name,
      'expand': widget.expand,
      // ignore: deprecated_member_use
      'color': widget.color?.value,
      'fontSize': widget.textStyle?.fontSize,
      'fontWeight': widget.textStyle?.fontWeight?.index,
      // ignore: deprecated_member_use
      'textColor': widget.textStyle?.color?.value,
    };
  }

  Future<void> _onPlatformViewCreated(int id) async {
    _channel = MethodChannel('flutter_cupertino/button_$id');
    _channel?.setMethodCallHandler(_handleMethodCall);
    // Request intrinsic size after a short delay to let the view settle
    await Future.delayed(const Duration(milliseconds: 50));
    _requestIntrinsicSize();
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
              height: _intrinsicHeight ?? 34,
              child: platformView,
            );
          },
        );
      }

      // Use intrinsic size from native view, with defaults until size is received
      // Default: 80x34 (reasonable button size)
      return SizedBox(
        width: _intrinsicWidth ?? 80,
        height: _intrinsicHeight ?? 34,
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

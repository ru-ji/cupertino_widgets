import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class CupertinoNativeToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final Color? activeColor;
  final TextStyle? textStyle;
  final double? width;
  final double? height;

  const CupertinoNativeToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.activeColor,
    this.textStyle,
    this.width,
    this.height,
  });

  @override
  State<CupertinoNativeToggle> createState() => _CupertinoNativeToggleState();
}

class _CupertinoNativeToggleState extends State<CupertinoNativeToggle> {
  MethodChannel? _channel;
  double? _intrinsicWidth;
  double? _intrinsicHeight;

  @override
  void didUpdateWidget(covariant CupertinoNativeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.label != widget.label ||
        oldWidget.activeColor != widget.activeColor ||
        oldWidget.textStyle != widget.textStyle) {
      _updateToggle();
    }
  }

  void _updateToggle() {
    _channel?.invokeMethod('updateToggle', _toMap()).then((_) {
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
      // Ignore errors
    }
  }

  Map<String, dynamic> _toMap() {
    return {
      'value': widget.value,
      'label': widget.label,
      // ignore: deprecated_member_use
      'color': widget.activeColor?.value,
      'fontSize': widget.textStyle?.fontSize,
      'fontWeight': widget.textStyle?.fontWeight?.index,
      // ignore: deprecated_member_use
      'textColor': widget.textStyle?.color?.value,
    };
  }

  Future<void> _onPlatformViewCreated(int id) async {
    _channel = MethodChannel('flutter_cupertino/toggle_$id');
    _channel?.setMethodCallHandler(_handleMethodCall);
    await Future.delayed(const Duration(milliseconds: 50));
    _requestIntrinsicSize();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onChanged') {
      final bool newValue = call.arguments;
      widget.onChanged?.call(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final platformView = UiKitView(
        viewType: 'com.example.flutter_cupertino/cupertino_native_toggle',
        layoutDirection: TextDirection.ltr,
        creationParams: _toMap(),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );

      // If explicit width/height provided, use them
      if (widget.width != null || widget.height != null) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: platformView,
        );
      }

      // If label is present, fill available width (typical iOS list row behavior)
      if (widget.label != null) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth.isInfinite
                ? (_intrinsicWidth ?? 200.0)
                : constraints.maxWidth;
            return SizedBox(
              width: width,
              height: _intrinsicHeight ?? 44.0,
              child: platformView,
            );
          },
        );
      }

      // Use intrinsic size from native view, with defaults until size is received
      // Default: 51x31 for bare toggle
      return SizedBox(
        width: _intrinsicWidth ?? 51.0,
        height: _intrinsicHeight ?? 31.0,
        child: platformView,
      );
    }

    // Fallback for non-iOS
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) Text(widget.label!),
        Switch(
          value: widget.value,
          onChanged: widget.onChanged,
          activeThumbColor: widget.activeColor,
        ),
      ],
    );
  }
}

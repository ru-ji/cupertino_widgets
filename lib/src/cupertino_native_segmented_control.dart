import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class CupertinoNativeSegmentedControl extends StatefulWidget {
  final List<String> children;
  final int groupValue;
  final ValueChanged<int>? onValueChanged;
  final Color? color;
  final double? width;
  final double? height;

  const CupertinoNativeSegmentedControl({
    super.key,
    required this.children,
    required this.groupValue,
    this.onValueChanged,
    this.color,
    this.width,
    this.height,
  });

  @override
  State<CupertinoNativeSegmentedControl> createState() =>
      _CupertinoNativeSegmentedControlState();
}

class _CupertinoNativeSegmentedControlState
    extends State<CupertinoNativeSegmentedControl> {
  MethodChannel? _channel;
  double? _intrinsicWidth;
  double? _intrinsicHeight;

  @override
  void didUpdateWidget(covariant CupertinoNativeSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.children, widget.children) ||
        oldWidget.groupValue != widget.groupValue ||
        oldWidget.color != widget.color) {
      _updateControl();
    }
  }

  void _updateControl() {
    _channel?.invokeMethod('updateSegmentedControl', _toMap()).then((_) {
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
      'items': widget.children,
      'selectedIndex': widget.groupValue,
      // ignore: deprecated_member_use
      'color': widget.color?.value,
    };
  }

  Future<void> _onPlatformViewCreated(int id) async {
    _channel = MethodChannel('flutter_cupertino/segmented_$id');
    _channel?.setMethodCallHandler(_handleMethodCall);
    await Future.delayed(const Duration(milliseconds: 50));
    _requestIntrinsicSize();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onValueChanged') {
      final int newValue = call.arguments;
      widget.onValueChanged?.call(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final platformView = UiKitView(
        viewType: 'com.example.flutter_cupertino/cupertino_native_segmented',
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

      // Use intrinsic size from native view, with defaults until size is received
      // Default: full width x 32 height for segmented control
      return SizedBox(
        width: _intrinsicWidth ?? 200,
        height: _intrinsicHeight ?? 32,
        child: platformView,
      );
    }

    // Fallback for non-iOS
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.children.length, (index) {
          final isSelected = widget.groupValue == index;
          return GestureDetector(
            onTap: () => widget.onValueChanged?.call(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: isSelected
                  ? (widget.color ?? const Color(0xFF007AFF))
                  : null,
              child: Center(
                child: Text(
                  widget.children[index],
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF000000),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'internal/native_platform_view_mixin.dart';

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
    extends State<CupertinoNativeSegmentedControl>
    with NativePlatformViewStateMixin {
  @override
  void didUpdateWidget(covariant CupertinoNativeSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.children, widget.children) ||
        oldWidget.groupValue != widget.groupValue ||
        oldWidget.color != widget.color) {
      updateNativeView('updateSegmentedControl', _toMap());
    }
  }

  Map<String, dynamic> _toMap() {
    return {
      'items': widget.children,
      'selectedIndex': widget.groupValue,
      'color': widget.color?.toARGB32(),
    };
  }

  Future<void> _onPlatformViewCreated(int id) async {
    setUpChannel(
      id,
      'cupertino_widgets/segmented_$id',
      onMethodCall: _handleMethodCall,
    );
    await Future.delayed(const Duration(milliseconds: 50));
    requestIntrinsicSize();
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
        viewType: 'com.example.cupertino_widgets/cupertino_native_segmented',
        layoutDirection: TextDirection.ltr,
        creationParams: _toMap(),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        // Claim drags immediately so press-and-slide across segments reaches
        // the native control instead of being taken by Flutter's gesture arena.
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
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
        width: intrinsicWidth ?? 200,
        height: intrinsicHeight ?? 32,
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

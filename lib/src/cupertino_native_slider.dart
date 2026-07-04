import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'internal/native_platform_view_mixin.dart';

class CupertinoNativeSlider extends StatefulWidget {
  const CupertinoNativeSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.activeColor,
    this.thumbColor,
  }) : assert(min <= max),
       assert(value >= min && value <= max);

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final Color? activeColor;
  final Color? thumbColor;

  @override
  State<CupertinoNativeSlider> createState() => _CupertinoNativeSliderState();
}

class _CupertinoNativeSliderState extends State<CupertinoNativeSlider>
    with NativePlatformViewStateMixin {
  @override
  Widget build(BuildContext context) {
    const String viewType =
        'com.example.flutter_cupertino/cupertino_native_slider';
    final Map<String, dynamic> creationParams = <String, dynamic>{
      'value': widget.value,
      'min': widget.min,
      'max': widget.max,
      'divisions': widget.divisions,
      'activeColor': widget.activeColor?.toARGB32(),
      'thumbColor': widget.thumbColor?.toARGB32(),
      'isEnabled': widget.onChanged != null,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use available width or default to 200 if unbounded
        final effectiveWidth = constraints.maxWidth.isInfinite
            ? 200.0
            : constraints.maxWidth;

        return SizedBox(
          width: effectiveWidth,
          height: 44, // Standard height
          child: UiKitView(
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onPlatformViewCreated,
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ),
        );
      },
    );
  }

  void _onPlatformViewCreated(int id) {
    setUpChannel(
      id,
      'adaptive_slider_$id',
      onMethodCall: _handleMethodCall,
    );
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onChanged') {
      if (widget.onChanged != null) {
        final double value = call.arguments as double;
        widget.onChanged!(value);
      }
    }
  }

  @override
  void didUpdateWidget(CupertinoNativeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.min != widget.min ||
        oldWidget.max != widget.max ||
        oldWidget.activeColor != widget.activeColor ||
        oldWidget.onChanged != widget.onChanged) {
      updateNativeView('updateProps', {
        'value': widget.value,
        'min': widget.min,
        'max': widget.max,
        'activeColor': widget.activeColor?.toARGB32(),
        'thumbColor': widget.thumbColor?.toARGB32(),
        'isEnabled': widget.onChanged != null,
      }, refreshIntrinsicSize: false);
    }
  }
}

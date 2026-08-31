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
        'com.example.cupertino_widgets/cupertino_native_slider';
    final Map<String, dynamic> creationParams = <String, dynamic>{
      'value': widget.value,
      'min': widget.min,
      'max': widget.max,
      'divisions': widget.divisions,
      'activeColor': widget.activeColor?.toARGB32(),
      'thumbColor': widget.thumbColor?.toARGB32(),
      'isEnabled': widget.onChanged != null,
    };

    // The slider fills the width offered, so only its height needs stating:
    // SwiftUI's own, through the same `getIntrinsicSize` round trip the button
    // makes. 44 is the standard control height and stands in until that lands.
    return SizedBox(
      height: intrinsicHeight ?? 44,
      child: UiKitView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
        },
      ),
    );
  }

  Future<void> _onPlatformViewCreated(int id) async {
    setUpChannel(id, 'adaptive_slider_$id', onMethodCall: _handleMethodCall);
    requestIntrinsicSize();
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

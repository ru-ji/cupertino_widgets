import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'internal/native_platform_view_mixin.dart';

enum CupertinoNativeProgressStyle { automatic, linear, circular }

class CupertinoNativeProgressIndicator extends StatefulWidget {
  const CupertinoNativeProgressIndicator({
    super.key,
    this.value,
    this.total = 1.0,
    this.label,
    this.style = CupertinoNativeProgressStyle.automatic,
    this.activeColor,
  });

  /// The progress value.
  /// If null, loops indefinitely (indeterminate).
  /// If provided, displays progress from 0.0 to [total].
  final double? value;

  /// The total value corresponding to 100% progress. Defaults to 1.0.
  final double total;

  /// An optional label to display with the progress.
  final String? label;

  /// The style of the progress view.
  final CupertinoNativeProgressStyle style;

  /// The tint color of the progress view.
  final Color? activeColor;

  @override
  State<CupertinoNativeProgressIndicator> createState() =>
      _CupertinoNativeProgressIndicatorState();
}

class _CupertinoNativeProgressIndicatorState
    extends State<CupertinoNativeProgressIndicator>
    with NativePlatformViewStateMixin {
  Map<String, dynamic> _toMap() {
    return {
      'value': widget.value,
      'total': widget.total,
      'label': widget.label,
      'style': widget.style.index,
      'color': widget.activeColor?.toARGB32(),
    };
  }

  void _onPlatformViewCreated(int id) {
    setUpChannel(id, 'cupertino_widgets/progress_$id');
  }

  @override
  void didUpdateWidget(CupertinoNativeProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value ||
        widget.total != oldWidget.total ||
        widget.label != oldWidget.label ||
        widget.style != oldWidget.style ||
        widget.activeColor != oldWidget.activeColor) {
      updateNativeView('updateProgress', _toMap(), refreshIntrinsicSize: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Circular progress: fixed 20x20
      // Linear progress: stretch width, 4 height (or 44 with label)
      final double? width =
          widget.style == CupertinoNativeProgressStyle.circular ? 20 : null;
      final double height = widget.style == CupertinoNativeProgressStyle.linear
          ? (widget.label != null ? 44 : 4)
          : 20;

      return LayoutBuilder(
        builder: (context, constraints) {
          // For linear style, use available width or default to 200
          final effectiveWidth =
              widget.style == CupertinoNativeProgressStyle.circular
              ? 20.0
              : (constraints.maxWidth.isInfinite
                    ? 200.0
                    : constraints.maxWidth);

          return SizedBox(
            width: width ?? effectiveWidth,
            height: height,
            child: UiKitView(
              viewType:
                  'com.example.cupertino_widgets/cupertino_native_progress',
              layoutDirection: TextDirection.ltr,
              creationParams: _toMap(),
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _onPlatformViewCreated,
            ),
          );
        },
      );
    }

    // Fallback or Android impl could go here (e.g. CircularProgressIndicator)
    return const SizedBox();
  }
}

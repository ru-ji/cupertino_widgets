import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Shared `MethodChannel` + intrinsic-size machinery for widgets that host a
/// native `UiKitView`. Every `CupertinoNative*` widget re-implemented this
/// identically; this mixin is the single copy.
///
/// Each widget still owns its own `_toMap()` (field set differs per widget),
/// its own `didUpdateWidget` diff (field list differs), and its own `build()`
/// (layout/fallback behavior differs per widget) - only the channel wiring
/// and intrinsic-size request/response plumbing is shared here.
mixin NativePlatformViewStateMixin<T extends StatefulWidget> on State<T> {
  MethodChannel? channel;
  double? intrinsicWidth;
  double? intrinsicHeight;

  /// Creates the method channel for this platform view instance and wires up
  /// [onMethodCall] to handle callbacks invoked from the native side.
  void setUpChannel(
    int id,
    String channelName, {
    Future<dynamic> Function(MethodCall call)? onMethodCall,
  }) {
    channel = MethodChannel(channelName);
    if (onMethodCall != null) {
      channel?.setMethodCallHandler(onMethodCall);
    }
  }

  /// Asks the native view for its intrinsic content size and rebuilds with it
  /// once available. Safe to call before the channel is ready or after unmount.
  Future<void> requestIntrinsicSize() async {
    if (channel == null) return;
    try {
      final result = await channel!.invokeMethod<Map>('getIntrinsicSize');
      if (result != null && mounted) {
        final w = (result['width'] as num?)?.toDouble();
        final h = (result['height'] as num?)?.toDouble();
        if (w != null && h != null && w > 0 && h > 0) {
          setState(() {
            intrinsicWidth = w;
            intrinsicHeight = h;
          });
        }
      }
    } catch (_) {
      // View may not be ready yet - ignore.
    }
  }

  /// Sends updated config to the native view via [method], then re-requests
  /// the intrinsic size (most widgets resize when their config changes).
  void updateNativeView(
    String method,
    Map<String, dynamic> args, {
    bool refreshIntrinsicSize = true,
  }) {
    final future = channel?.invokeMethod(method, args);
    if (refreshIntrinsicSize) {
      future?.then((_) => requestIntrinsicSize());
    }
  }
}

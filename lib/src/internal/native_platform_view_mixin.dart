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
  ///
  /// Retried, because the first answer is often no answer: a hosted SwiftUI
  /// view that has not been laid out yet measures as zero, and the native side
  /// reports that rather than a made-up number. A single early call would leave
  /// the widget on its Dart-side default forever — which is how a switch ended
  /// up in a box smaller than the control UIKit actually draws, spilling past
  /// its own bounds. Each attempt waits one more frame than the last, and the
  /// loop stops the moment a real size lands.
  ///
  /// The default schedule spans about 1.2s. Six attempts (~340ms) looked like
  /// plenty until a control was built *during* a route transition or inside a
  /// lazily-built list: laid out late, past the last attempt, it kept the
  /// Dart-side default for good — and a default that under-shoots is exactly
  /// the spill above, permanently this time. Giving up early costs a broken
  /// layout; retrying costs a few method calls on a view nobody sees yet.
  Future<void> requestIntrinsicSize({int attempts = 12}) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (!mounted || channel == null) return;
      try {
        final result = await channel!.invokeMethod<Map>('getIntrinsicSize');
        final w = (result?['width'] as num?)?.toDouble();
        final h = (result?['height'] as num?)?.toDouble();
        if (w != null && h != null && w > 0 && h > 0) {
          if (!mounted) return;
          setState(() {
            intrinsicWidth = w;
            intrinsicHeight = h;
          });
          return;
        }
      } catch (_) {
        // View may not be ready yet - ignore and try again.
      }
      await Future<void>.delayed(Duration(milliseconds: 16 * (attempt + 1)));
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

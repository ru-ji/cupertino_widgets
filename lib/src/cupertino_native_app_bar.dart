import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'models/cupertino_native_bar_item.dart';

/// A native iOS navigation bar rendered by a bare `UINavigationBar` in a
/// transparent container — no UINavigationController, so Flutter content
/// stays visible behind the bar's glass.
///
/// Usable directly as `Scaffold.appBar` (it implements
/// [PreferredSizeWidget]); combine with `extendBodyBehindAppBar: true` so the
/// body scrolls behind the bar. Standalone large titles render statically —
/// collapse-on-scroll requires `CupertinoNativeScaffold`, where the scroll
/// view is native.
class CupertinoNativeAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final bool largeTitle;

  /// Leading/trailing entries: [CupertinoNativeBarItem] renders its own glass
  /// capsule, [CupertinoNativeBarItemGroup] renders several buttons sharing
  /// one capsule.
  final List<CupertinoNativeBarEntry> leading;
  final List<CupertinoNativeBarEntry> trailing;
  final Color? tint;
  final void Function(String actionId)? onAction;

  const CupertinoNativeAppBar({
    super.key,
    required this.title,
    this.largeTitle = false,
    this.leading = const [],
    this.trailing = const [],
    this.tint,
    this.onAction,
  });

  @override
  Size get preferredSize => Size.fromHeight(largeTitle ? 96 : 44);

  /// Serialized form, also used by `CupertinoNativeScaffold` to configure
  /// its pages (where this widget acts as a config carrier, not a widget).
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'displayMode': largeTitle ? 'large' : 'inline',
      'leading': leading.map((e) => e.toMap()).toList(),
      'trailing': trailing.map((e) => e.toMap()).toList(),
    };
  }

  @override
  State<CupertinoNativeAppBar> createState() => _CupertinoNativeAppBarState();
}

class _CupertinoNativeAppBarState extends State<CupertinoNativeAppBar> {
  MethodChannel? _channel;
  bool? _lastIsDark;
  Map<String, dynamic>? _lastConfig;

  bool get _isDark =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark;

  Map<String, dynamic> _config() {
    return {
      ...widget.toMap(),
      'tint': widget.tint?.toARGB32(),
    };
  }

  @override
  void didUpdateWidget(covariant CupertinoNativeAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPropsToNative();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBrightness();
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    final channel = MethodChannel('flutter_cupertino/appbar_$id');
    _channel = channel;
    channel.setMethodCallHandler(_handleMethodCall);
    _lastIsDark = _isDark;
    _lastConfig = _config();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onBarAction') {
      final String? id = call.arguments['id'];
      if (id != null) {
        widget.onAction?.call(id);
      }
    }
  }

  Future<void> _syncPropsToNative() async {
    final channel = _channel;
    if (channel == null) return;
    final config = _config();
    // Config is a small nested map of primitives; string comparison is a
    // cheap deep-equality check.
    if (_lastConfig.toString() != config.toString()) {
      await channel.invokeMethod('updateAppBar', config);
      _lastConfig = config;
    }
  }

  Future<void> _syncBrightness() async {
    final channel = _channel;
    if (channel == null) return;
    final isDark = _isDark;
    if (_lastIsDark != isDark) {
      await channel.invokeMethod('setBrightness', {'isDark': isDark});
      _lastIsDark = isDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Scaffold hands the appBar slot the status-bar region too; the native
      // side pins the bar exactly below the reported status-bar height.
      return UiKitView(
        viewType: 'com.example.flutter_cupertino/cupertino_native_appbar',
        layoutDirection: TextDirection.ltr,
        creationParams: {
          ..._config(),
          'isDark': _isDark,
          'statusBarHeight': MediaQuery.paddingOf(context).top,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }

    // Fallback for non-iOS: a plain title bar.
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: widget.preferredSize.height,
        child: Center(
          child: Text(
            widget.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

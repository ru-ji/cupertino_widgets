import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'models/cupertino_native_tab.dart';

/// Mirrors SwiftUI's `tabBarMinimizeBehavior`. Only takes effect inside
/// `CupertinoNativeScaffold` (iOS 26+), where the scroll view is native.
enum CupertinoNativeTabBarMinimizeBehavior {
  automatic,
  onScrollDown,
  onScrollUp,
  never,
}

/// A native iOS tab bar rendered by a bare `UITabBar` in a transparent
/// container — no UITabBarController, so Flutter content stays visible
/// around and behind the bar.
///
/// Best used as a `Stack` overlay (`Align(alignment: Alignment.bottomCenter)`)
/// over your content rather than in `Scaffold.bottomNavigationBar`, so the
/// bar can hug its intrinsic width ([shrinkCentered]) and float like the
/// iOS 26 pill. With [split] the trailing [rightCount] tabs (e.g. a search
/// tab) render in their own detached bar.
class CupertinoNativeTabBar extends StatefulWidget {
  final List<CupertinoNativeTab> tabs;

  /// Id of the selected tab (see [CupertinoNativeTab.id]).
  final String selection;
  final Function(String)? onSelectionChanged;
  final Color? accentColor;
  final Color? backgroundColor;

  /// Fixed height; when null the native bar's intrinsic height is used.
  final double? height;

  /// Splits the trailing [rightCount] tabs into a detached bar.
  final bool split;
  final int rightCount;
  final double splitSpacing;

  /// When not split, size the bar to its content width (floating pill).
  final bool shrinkCentered;

  /// Only meaningful when this config is passed to `CupertinoNativeScaffold`.
  final CupertinoNativeTabBarMinimizeBehavior minimizeBehavior;

  const CupertinoNativeTabBar({
    super.key,
    required this.tabs,
    required this.selection,
    this.onSelectionChanged,
    this.accentColor,
    this.backgroundColor,
    this.height,
    this.split = false,
    this.rightCount = 1,
    this.splitSpacing = 8.0,
    this.shrinkCentered = true,
    this.minimizeBehavior = CupertinoNativeTabBarMinimizeBehavior.automatic,
  });

  /// Serialized form consumed by `CupertinoNativeScaffold` (which renders its
  /// own SwiftUI tab bar; standalone rendering uses different params).
  Map<String, dynamic> toMap() {
    return {
      'tabs': tabs.map((e) => e.toMap()).toList(),
      'selection': selection,
      'accentColor': accentColor?.toARGB32(),
      'minimizeBehavior': minimizeBehavior.name,
    };
  }

  @override
  State<CupertinoNativeTabBar> createState() => _CupertinoNativeTabBarState();
}

class _CupertinoNativeTabBarState extends State<CupertinoNativeTabBar> {
  MethodChannel? _channel;
  double? _intrinsicHeight;
  double? _intrinsicWidth;
  int? _lastIndex;
  int? _lastTint;
  int? _lastBg;
  bool? _lastIsDark;
  List<String>? _lastLabels;
  List<String>? _lastSymbols;
  bool? _lastSplit;
  int? _lastRightCount;
  double? _lastSplitSpacing;

  bool get _isDark =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark;

  int get _selectedIndex {
    final idx = widget.tabs.indexWhere((t) => t.id == widget.selection);
    return idx < 0 ? 0 : idx;
  }

  List<String> get _labels => widget.tabs.map((t) => t.title).toList();
  List<String> get _symbols =>
      widget.tabs.map((t) => t.systemImage ?? '').toList();

  @override
  void didUpdateWidget(covariant CupertinoNativeTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPropsToNative();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBrightness();
    _syncPropsToNative();
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  void _onPlatformViewCreated(int id) {
    final channel = MethodChannel('flutter_cupertino/tabbar_$id');
    _channel = channel;
    channel.setMethodCallHandler(_handleMethodCall);
    _lastIndex = _selectedIndex;
    _lastTint = widget.accentColor?.toARGB32();
    _lastBg = widget.backgroundColor?.toARGB32();
    _lastIsDark = _isDark;
    _lastLabels = _labels;
    _lastSymbols = _symbols;
    _lastSplit = widget.split;
    _lastRightCount = widget.rightCount;
    _lastSplitSpacing = widget.splitSpacing;
    _requestIntrinsicSize();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'valueChanged') {
      final args = call.arguments as Map?;
      final idx = (args?['index'] as num?)?.toInt();
      if (idx != null && idx != _lastIndex && idx < widget.tabs.length) {
        _lastIndex = idx;
        widget.onSelectionChanged?.call(widget.tabs[idx].id);
      }
    }
  }

  Future<void> _syncPropsToNative() async {
    final channel = _channel;
    if (channel == null) return;

    final idx = _selectedIndex;
    final tint = widget.accentColor?.toARGB32();
    final bg = widget.backgroundColor?.toARGB32();
    final labels = _labels;
    final symbols = _symbols;

    if (_lastIndex != idx) {
      await channel.invokeMethod('setSelectedIndex', {'index': idx});
      _lastIndex = idx;
    }

    final style = <String, dynamic>{};
    if (_lastTint != tint && tint != null) {
      style['tint'] = tint;
      _lastTint = tint;
    }
    if (_lastBg != bg && bg != null) {
      style['backgroundColor'] = bg;
      _lastBg = bg;
    }
    if (style.isNotEmpty) {
      await channel.invokeMethod('setStyle', style);
    }

    if (!listEquals(_lastLabels, labels) || !listEquals(_lastSymbols, symbols)) {
      await channel.invokeMethod('setItems', {
        'labels': labels,
        'sfSymbols': symbols,
        'selectedIndex': idx,
      });
      _lastLabels = labels;
      _lastSymbols = symbols;
      _requestIntrinsicSize();
    }

    if (_lastSplit != widget.split ||
        _lastRightCount != widget.rightCount ||
        _lastSplitSpacing != widget.splitSpacing) {
      await channel.invokeMethod('setLayout', {
        'split': widget.split,
        'rightCount': widget.rightCount,
        'splitSpacing': widget.splitSpacing,
        'selectedIndex': idx,
      });
      _lastSplit = widget.split;
      _lastRightCount = widget.rightCount;
      _lastSplitSpacing = widget.splitSpacing;
      _requestIntrinsicSize();
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

  Future<void> _requestIntrinsicSize() async {
    if (widget.height != null) return;
    final channel = _channel;
    if (channel == null) return;
    try {
      final size = await channel.invokeMethod<Map>('getIntrinsicSize');
      final h = (size?['height'] as num?)?.toDouble();
      final w = (size?['width'] as num?)?.toDouble();
      if (!mounted) return;
      setState(() {
        if (h != null && h > 0) _intrinsicHeight = h;
        if (w != null && w > 0) _intrinsicWidth = w;
      });
    } catch (_) {
      // View may not be ready yet.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      // Simple fallback for non-iOS platforms.
      return SizedBox(
        height: widget.height ?? 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < widget.tabs.length; i++)
              GestureDetector(
                onTap: () =>
                    widget.onSelectionChanged?.call(widget.tabs[i].id),
                child: Text(
                  widget.tabs[i].title,
                  style: TextStyle(
                    color: i == _selectedIndex
                        ? (widget.accentColor ?? const Color(0xFF007AFF))
                        : const Color(0xFF8E8E93),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final creationParams = <String, dynamic>{
      'labels': _labels,
      'sfSymbols': _symbols,
      'selectedIndex': _selectedIndex,
      'isDark': _isDark,
      'tint': widget.accentColor?.toARGB32(),
      'backgroundColor': widget.backgroundColor?.toARGB32(),
      'split': widget.split,
      'rightCount': widget.rightCount,
      'splitSpacing': widget.splitSpacing,
    };

    final platformView = UiKitView(
      viewType: 'com.example.flutter_cupertino/cupertino_native_tabbar',
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );

    final h = widget.height ?? _intrinsicHeight ?? 50.0;
    if (!widget.split && widget.shrinkCentered) {
      return SizedBox(height: h, width: _intrinsicWidth, child: platformView);
    }
    return SizedBox(height: h, child: platformView);
  }
}

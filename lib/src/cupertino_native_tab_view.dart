import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'models/cupertino_native_tab.dart';

class CupertinoNativeTabView extends StatefulWidget {
  final List<CupertinoNativeTab> tabs;
  final String initialSelection;
  final Function(String)? onSelectionChanged;

  /// The color of the active tab item
  final Color? accentColor;

  const CupertinoNativeTabView({
    super.key,
    required this.tabs,
    required this.initialSelection,
    this.onSelectionChanged,
    this.accentColor,
  });

  @override
  State<CupertinoNativeTabView> createState() => _CupertinoNativeTabViewState();
}

class _CupertinoNativeTabViewState extends State<CupertinoNativeTabView> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(covariant CupertinoNativeTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.tabs, widget.tabs) ||
        oldWidget.accentColor != widget.accentColor) {
      _updateTabView();
    }
  }

  void _updateTabView() {
    _channel?.invokeMethod('updateTabView', _toMap());
  }

  Map<String, dynamic> _toMap() {
    return {
      'tabs': widget.tabs.map((e) => e.toMap()).toList(),
      'selection': widget.initialSelection,
      // ignore: deprecated_member_use
      'accentColor': widget.accentColor?.value,
    };
  }

  Future<void> _onPlatformViewCreated(int id) async {
    _channel = MethodChannel('flutter_cupertino/tabview_$id');
    _channel?.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSelectionChanged':
        final String? id = call.arguments['selection'];
        if (id != null) {
          widget.onSelectionChanged?.call(id);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const String viewType =
        'com.example.flutter_cupertino/cupertino_native_tabview';
    final Map<String, dynamic> creationParams = _toMap();

    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }
}

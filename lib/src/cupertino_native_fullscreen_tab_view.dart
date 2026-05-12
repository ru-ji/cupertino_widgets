import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/cupertino_native_tab.dart';

class CupertinoNativeFullscreenTabView extends StatefulWidget {
  final List<CupertinoNativeTab> tabs;
  final String initialSelection;
  final Function(String)? onSelectionChanged;
  final Color? accentColor;

  /// The name of the single `@pragma('vm:entry-point')` Dart function
  /// that will be used for every tab's FlutterEngine.
  ///
  /// Inside that function, call [CupertinoNativeFullscreenTabView.run]
  /// with a map of tab id -> widget builder.
  final String entryPoint;

  const CupertinoNativeFullscreenTabView({
    super.key,
    required this.tabs,
    required this.initialSelection,
    required this.entryPoint,
    this.onSelectionChanged,
    this.accentColor,
  }) : assert(tabs.length > 0, 'tabs must not be empty');

  /// Call this inside your `@pragma('vm:entry-point')` function.
  ///
  /// It reads the tab id from the engine's initial route and runs
  /// the matching widget.
  static void run(Map<String, Widget Function()> builders) {
    final tabId = ui.PlatformDispatcher.instance.defaultRouteName;
    final builder = builders[tabId];

    // We wrap the child in a widget tree that mimics a standard Flutter app
    // but without Scaffold or MaterialApp, which naturally try to expand to double.infinity.
    // By keeping it wrapped only in basic inherited widgets, we allow it to be sized
    // by its intrinsic height, enabling `isAutoResizable` on the SwiftUI side to handle scrolling.
    final child = builder != null ? builder() : const Text('Unknown tab');

    runApp(_DynamicEnvWrapper(child: child));
  }

  @override
  State<CupertinoNativeFullscreenTabView> createState() =>
      _CupertinoNativeFullscreenTabViewState();
}

class _DynamicEnvWrapper extends StatefulWidget {
  final Widget child;
  const _DynamicEnvWrapper({required this.child});

  @override
  State<_DynamicEnvWrapper> createState() => _DynamicEnvWrapperState();
}

class _DynamicEnvWrapperState extends State<_DynamicEnvWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {}); // Trigger rebuild on theme change
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    setState(() {}); // Trigger rebuild on locale change
  }

  @override
  Widget build(BuildContext context) {
    final platformDispatcher = ui.PlatformDispatcher.instance;
    final brightness = platformDispatcher.platformBrightness;
    final locale = platformDispatcher.locales.isNotEmpty
        ? platformDispatcher.locales.first
        : const Locale('en', 'US');

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Localizations(
        locale: locale,
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        child: Theme(
          data: brightness == ui.Brightness.dark
              ? ThemeData.dark()
              : ThemeData.light(),
          // Ensure the main widget takes the full width but its natural height.
          // Material provides the default text styles so text isn't white-on-white.
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(width: double.infinity, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _CupertinoNativeFullscreenTabViewState
    extends State<CupertinoNativeFullscreenTabView> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(covariant CupertinoNativeFullscreenTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.tabs, widget.tabs) ||
        oldWidget.accentColor != widget.accentColor ||
        oldWidget.initialSelection != widget.initialSelection ||
        oldWidget.entryPoint != widget.entryPoint) {
      _updateTabView();
    }
  }

  void _updateTabView() {
    _channel?.invokeMethod('updateFullscreenTabView', _toMap());
  }

  Map<String, dynamic> _toMap() {
    return {
      'tabs': widget.tabs.map((e) => e.toMap()).toList(),
      'selection': widget.initialSelection,
      'entryPoint': widget.entryPoint,
      // ignore: deprecated_member_use
      'accentColor': widget.accentColor?.value,
    };
  }

  Future<void> _onPlatformViewCreated(int id) async {
    _channel = MethodChannel('flutter_cupertino/fullscreen_tabview_$id');
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
        'com.example.flutter_cupertino/cupertino_native_fullscreen_tabview';
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

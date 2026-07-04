import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cupertino_native_app_bar.dart';
import 'cupertino_native_tab_bar.dart';
import 'internal/native_platform_view_mixin.dart';

/// A page pushed onto a [CupertinoNativeScaffold]'s native NavigationStack.
/// [route] must match a builder registered in [CupertinoNativeScaffold.run];
/// [appBar] configures the destination's navigation bar (title, items).
class CupertinoNativeScaffoldPage {
  final String route;
  final CupertinoNativeAppBar? appBar;

  const CupertinoNativeScaffoldPage({required this.route, this.appBar});

  Map<String, dynamic> toMap() {
    return {'route': route, 'appBar': appBar?.toMap()};
  }
}

/// Drives a [CupertinoNativeScaffold]'s navigation from the host isolate
/// (the widget tree that created the scaffold). Inside body isolates use the
/// static [CupertinoNativeScaffold.push]/[CupertinoNativeScaffold.pop].
class CupertinoNativeScaffoldController {
  MethodChannel? _channel;

  Future<void> push(CupertinoNativeScaffoldPage page) async {
    await _channel?.invokeMethod('push', page.toMap());
  }

  Future<void> pop() async {
    await _channel?.invokeMethod('pop');
  }
}

/// Which iOS 26 Liquid Glass scroll-edge-effect style the scaffold's native
/// scroll views use (no effect below iOS 26).
enum CupertinoNativeScrollEdgeEffect { automatic, soft, hard }

/// A pure SwiftUI scaffold: native NavigationStack (+ optional TabView) whose
/// pages are Flutter bodies embedded in native ScrollViews.
///
/// Native behaviors preserved: large-title collapse on scroll, tab bar
/// minimize (iOS 26), `.search` tab role (iOS 18+), system push/pop
/// transitions with toolbar morphing, and interactive back-swipe.
///
/// Navigation between scaffold pages happens on the NATIVE stack via
/// [CupertinoNativeScaffoldController.push] (host isolate) or the static
/// [push] (body isolates) — not Flutter's Navigator. Each body runs in its
/// own FlutterEngine. Register the route builders by calling [maybeRun] at
/// the top of your `main()` (no entry point needed), or with a custom
/// [entryPoint] function that calls [run]. Requires iOS 16+.
class CupertinoNativeScaffold extends StatefulWidget {
  /// Optional name of a `@pragma('vm:entry-point')` function that calls
  /// [run]. When null (default), body engines run your app's `main()` with a
  /// special route that [maybeRun] intercepts — add
  /// `if (CupertinoNativeScaffold.maybeRun(routes)) return;` as the first
  /// line of `main()`.
  final String? entryPoint;

  /// Root body route when no [tabBar] is given. With a [tabBar], each tab's
  /// `id` doubles as its body route.
  final String? body;

  /// Root navigation-bar config (also applied to each tab's root page).
  final CupertinoNativeAppBar? appBar;

  /// Optional native tab bar; enables tabbed mode.
  final CupertinoNativeTabBar? tabBar;

  final CupertinoNativeScaffoldController? controller;
  final void Function(String route, String actionId)? onBarAction;
  final Function(String)? onTabChanged;

  /// iOS 26 scroll edge effect style for the native scroll views.
  final CupertinoNativeScrollEdgeEffect scrollEdgeEffect;

  /// Reports the current tab's native stack (root route first) whenever a
  /// push/pop happens — including native back button and back-swipe.
  final void Function(List<String> routes)? onRouteChanged;

  const CupertinoNativeScaffold({
    super.key,
    this.entryPoint,
    this.body,
    this.appBar,
    this.tabBar,
    this.controller,
    this.onBarAction,
    this.onTabChanged,
    this.scrollEdgeEffect = CupertinoNativeScrollEdgeEffect.automatic,
    this.onRouteChanged,
  }) : assert(tabBar != null || body != null,
            'Provide a tabBar (tab ids double as body routes) or a body route');

  /// Well-known channel the native side attaches to every body engine.
  static const MethodChannel _bodyChannel =
      MethodChannel('flutter_cupertino/scaffold_body');

  /// Route prefix used when no custom [entryPoint] is given: body engines run
  /// `main()` with `cn-scaffold://<route>` as the initial route.
  static const String _routePrefix = 'cn-scaffold://';

  /// Call as the FIRST line of `main()`:
  /// `if (CupertinoNativeScaffold.maybeRun(routes)) return;`
  ///
  /// Returns true when this isolate is a scaffold body engine, in which case
  /// the matching route builder has been run and `main()` must not continue
  /// to `runApp`. Returns false in the regular app isolate.
  static bool maybeRun(Map<String, Widget Function()> builders) {
    final route = ui.PlatformDispatcher.instance.defaultRouteName;
    if (!route.startsWith(_routePrefix)) return false;
    final name = route.substring(_routePrefix.length);
    final builder = builders[name];
    final child = builder != null ? builder() : Text('Unknown route: $name');
    runApp(_DynamicEnvWrapper(child: _withExplicitWidth(child)));
    return true;
  }

  /// Call this inside your `@pragma('vm:entry-point')` function. It reads the
  /// route from the engine's initial route and runs the matching builder.
  static void run(Map<String, Widget Function()> builders) {
    final route = ui.PlatformDispatcher.instance.defaultRouteName;
    final builder = builders[route];

    // Wrap the body in basic inherited widgets only (no Scaffold/MaterialApp,
    // which expand to infinity) so the SwiftUI side can size it to its
    // natural height and let the native ScrollView own scrolling.
    final child = builder != null ? builder() : const Text('Unknown route');

    runApp(_DynamicEnvWrapper(child: _withExplicitWidth(child)));
  }

  /// The auto-resizable engine lays the root out with UNBOUNDED constraints
  /// and requires the top-level widget to pick explicit dimensions (the
  /// native view then adopts that size). Width = the screen; height comes
  /// from the content.
  static Widget _withExplicitWidth(Widget child) {
    final dispatcher = ui.PlatformDispatcher.instance;
    double width = 0;
    if (dispatcher.displays.isNotEmpty) {
      final display = dispatcher.displays.first;
      if (display.size.width > 0) {
        width = display.size.width / display.devicePixelRatio;
      }
    }
    if (width <= 0 && dispatcher.views.isNotEmpty) {
      final view = dispatcher.views.first;
      if (view.physicalSize.width > 0) {
        width = view.physicalSize.width / view.devicePixelRatio;
      }
    }
    if (width <= 0) width = 400; // last resort
    return SizedBox(width: width, child: child);
  }

  /// Pushes a page onto the enclosing scaffold's native stack. Only usable
  /// inside body isolates (widgets built via [run]).
  static Future<void> push(CupertinoNativeScaffoldPage page) {
    return _bodyChannel.invokeMethod('push', page.toMap());
  }

  /// Pops the enclosing scaffold's native stack. Only usable inside body
  /// isolates; the system back button and back-swipe also pop natively.
  static Future<void> pop() {
    return _bodyChannel.invokeMethod('pop');
  }

  /// Updates the root navigation bar's title. Only usable inside body isolates.
  static Future<void> setTitle(String title) {
    return _bodyChannel.invokeMethod('setTitle', {'title': title});
  }

  @override
  State<CupertinoNativeScaffold> createState() =>
      _CupertinoNativeScaffoldState();
}

/// Keeps body isolates in sync with platform brightness/locale changes,
/// since they run without a MaterialApp.
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
          child: Material(type: MaterialType.transparency, child: widget.child),
        ),
      ),
    );
  }
}

class _CupertinoNativeScaffoldState extends State<CupertinoNativeScaffold>
    with NativePlatformViewStateMixin {
  Map<String, dynamic> _toMap() {
    return {
      'entryPoint': widget.entryPoint,
      'body': widget.body,
      'appBar': widget.appBar?.toMap(),
      'tabBar': widget.tabBar?.toMap(),
      'scrollEdgeEffect': widget.scrollEdgeEffect.name,
    };
  }

  @override
  void didUpdateWidget(covariant CupertinoNativeScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldMap = {
      'entryPoint': oldWidget.entryPoint,
      'body': oldWidget.body,
      'appBar': oldWidget.appBar?.toMap(),
      'tabBar': oldWidget.tabBar?.toMap(),
      'scrollEdgeEffect': oldWidget.scrollEdgeEffect.name,
    };
    // Configs are nested maps of primitives; JSON comparison is a simple
    // deep-equality check.
    if (jsonEncode(oldMap) != jsonEncode(_toMap())) {
      updateNativeView('updateScaffold', _toMap(), refreshIntrinsicSize: false);
    }
  }

  Future<void> _onPlatformViewCreated(int id) async {
    setUpChannel(
      id,
      'flutter_cupertino/scaffold_$id',
      onMethodCall: _handleMethodCall,
    );
    widget.controller?._channel = channel;
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onBarAction':
        final String? route = call.arguments['route'];
        final String? id = call.arguments['id'];
        if (route != null && id != null) {
          widget.onBarAction?.call(route, id);
        }
        break;
      case 'onTabChanged':
        final String? selection = call.arguments['selection'];
        if (selection != null) {
          widget.onTabChanged?.call(selection);
        }
        break;
      case 'onRouteChanged':
        final List<dynamic>? routes = call.arguments['routes'];
        if (routes != null) {
          widget.onRouteChanged?.call(routes.cast<String>());
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const Center(child: Text('CupertinoNativeScaffold is iOS only'));
    }

    return UiKitView(
      viewType: 'com.example.flutter_cupertino/cupertino_native_scaffold',
      layoutDirection: TextDirection.ltr,
      creationParams: _toMap(),
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }
}

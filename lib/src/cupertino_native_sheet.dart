import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cupertino_native_app_bar.dart';
import 'cupertino_native_tab_bar.dart' show CupertinoNativeScrollEdgeEffect;
import 'cupertino_widgets_settings.dart';

/// The heights a [CupertinoNativeSheet] can rest at, mirroring
/// `UISheetPresentationController.Detent`.
enum CupertinoNativeSheetDetent { medium, large }

/// A native segmented control pinned under the sheet's navigation bar —
/// the `bottom` slot of [CupertinoNativeSheet.show].
class CupertinoNativeSheetSegmentedControl {
  const CupertinoNativeSheetSegmentedControl({
    required this.segments,
    this.selectedIndex = 0,
  });

  final List<String> segments;
  final int selectedIndex;
}

/// Presents a Flutter page as a **native iOS sheet** — the system page-sheet
/// modal that rises over the app and pushes the previous screen back and down
/// (what `showCupertinoSheet` imitates, here the real
/// `UISheetPresentationController`): system detents, grabber, corner radius
/// and the swipe-to-dismiss gesture are all UIKit's.
///
/// With an [CupertinoNativeAppBar] the sheet gets pinned native chrome, like
/// Safari's Page Menu: title, leading/trailing bar items (glass circles on
/// iOS 26), an optional native search field ([CupertinoNativeSearchField], as
/// on the native scaffold), an optional segmented control under the bar
/// ([CupertinoNativeSheetSegmentedControl]), and the Flutter body hosted in a
/// native ScrollView — content scrolls under the bar, and pulling down at the
/// top drags the sheet, the system way.
///
/// ```dart
/// await CupertinoNativeSheet.show(
///   route: 'newEvent', // same route table as CupertinoNativeScaffold bodies
///   appBar: CupertinoNativeAppBar(
///     title: 'New Event',
///     leading: [
///       CupertinoNativeBarItem(
///         icon: CupertinoNativeIcon.symbol(CupertinoSymbols.xmark),
///         actionId: 'close',
///       ),
///     ],
///     trailing: [CupertinoNativeBarItem(title: 'Add', actionId: 'add')],
///   ),
///   bottom: CupertinoNativeSheetSegmentedControl(
///     segments: ['Event', 'Reminder'],
///   ),
///   detents: [CupertinoNativeSheetDetent.medium, CupertinoNativeSheetDetent.large],
///   showGrabber: true,
///   onBarAction: (id) => CupertinoNativeSheet.dismiss(),
/// );
/// // The future completes when the sheet is dismissed.
/// ```
///
/// Inside the sheet's body, call [pop] to dismiss programmatically.
abstract final class CupertinoNativeSheet {
  static const _channel = MethodChannel('com.example.cupertino_widgets/alert');
  static const _bodyChannel = MethodChannel('cupertino_widgets/scaffold_body');
  static const _eventsChannel =
      MethodChannel('cupertino_widgets/sheet_events');

  static bool _eventsHandlerInstalled = false;
  static void Function(String actionId)? _onBarAction;
  static ValueChanged<int>? _onBottomChanged;
  static ValueChanged<String>? _onSearchChanged;
  static ValueChanged<String>? _onSearchSubmitted;

  /// Presents the sheet and completes when it has been dismissed (either by
  /// [dismiss]/[pop], a bar action calling them, or the user's swipe).
  ///
  /// [appBar] pins native chrome above the content; its
  /// [CupertinoNativeAppBar.search] field reports through [onSearchChanged] /
  /// [onSearchSubmitted]. [bottom] pins a native segmented control under the
  /// bar, reporting through [onBottomChanged]. Bar item taps report their
  /// `actionId` through [onBarAction].
  ///
  /// [isDark] pins the sheet's appearance; when null it follows the platform
  /// brightness.
  static Future<void> show({
    required String route,
    CupertinoNativeAppBar? appBar,
    CupertinoNativeSheetSegmentedControl? bottom,
    List<CupertinoNativeSheetDetent> detents = const [
      CupertinoNativeSheetDetent.large,
    ],
    bool showGrabber = false,
    double? cornerRadius,
    CupertinoNativeScrollEdgeEffect scrollEdgeEffect =
        CupertinoNativeScrollEdgeEffect.soft,
    Color? backgroundColor,
    bool? showLoadingIndicator,
    bool? isDark,
    void Function(String actionId)? onBarAction,
    ValueChanged<int>? onBottomChanged,
    ValueChanged<String>? onSearchChanged,
    ValueChanged<String>? onSearchSubmitted,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;

    _onBarAction = onBarAction;
    _onBottomChanged = onBottomChanged;
    _onSearchChanged = onSearchChanged;
    _onSearchSubmitted = onSearchSubmitted;
    _ensureEventsHandler();

    final dark = isDark ??
        ui.PlatformDispatcher.instance.platformBrightness == ui.Brightness.dark;
    try {
      await _channel.invokeMethod<void>('showSheet', {
        'route': route,
        'appBar': appBar?.toMap(),
        'bottomSegments': bottom?.segments,
        'bottomSelectedIndex': bottom?.selectedIndex,
        'detents': detents.map((d) => d.name).toList(),
        'showGrabber': showGrabber,
        'cornerRadius': cornerRadius,
        'scrollEdgeEffect': scrollEdgeEffect.name,
        'backgroundColor': backgroundColor?.toARGB32(),
        'showLoadingIndicator': showLoadingIndicator ??
            CupertinoWidgetsSettings.showLoadingIndicator,
        'isDark': dark,
      });
    } finally {
      _onBarAction = null;
      _onBottomChanged = null;
      _onSearchChanged = null;
      _onSearchSubmitted = null;
    }
  }

  static void _ensureEventsHandler() {
    if (_eventsHandlerInstalled) return;
    _eventsHandlerInstalled = true;
    _eventsChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'barAction':
          _onBarAction?.call(call.arguments as String);
        case 'segmentChanged':
          _onBottomChanged?.call(call.arguments as int);
        case 'searchChanged':
          _onSearchChanged?.call(call.arguments as String);
        case 'searchSubmitted':
          _onSearchSubmitted?.call(call.arguments as String);
      }
    });
  }

  /// Dismisses the currently presented sheet (from the main app's isolate).
  static Future<void> dismiss() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await _channel.invokeMethod<void>('dismissSheet');
  }

  /// Dismisses the sheet from **inside its own body** (the sheet's isolate).
  static Future<void> pop() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await _bodyChannel.invokeMethod<void>('pop');
  }
}

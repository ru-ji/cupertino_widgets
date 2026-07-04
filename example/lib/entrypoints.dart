import 'package:flutter/widgets.dart';

import 'pages/profile_tab_page.dart';
import 'pages/scaffold_bodies.dart';
import 'pages/search_tab_page.dart';
import 'pages/settings_tab_page.dart';

/// Route builders for every CupertinoNativeScaffold body (tab roots and
/// pushed pages alike). Consumed by `CupertinoNativeScaffold.maybeRun` at the
/// top of `main()` — no `@pragma('vm:entry-point')` function needed.
Map<String, Widget Function()> scaffoldRoutes() {
  return {
    'home': () => const ScaffoldHomeBody(),
    'search': () => const SearchTabPage(),
    'profile': () => const ProfileTabPage(),
    'settings': () => const SettingsTabPage(),
    'details': () => const ScaffoldDetailsBody(),
  };
}

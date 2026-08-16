import 'package:flutter/cupertino.dart' show CupertinoColors;
import 'package:flutter/widgets.dart';
import 'package:cupertino_widgets/cupertino_widgets.dart';

import '../widgets/settings_ui.dart';
import 'home_tab_page.dart';
import 'profile_tab_page.dart';
import 'search_tab_page.dart';
import 'settings_tab_page.dart';

/// The standalone native tab bar floating over ordinary Flutter content. The
/// bar is a bare UIKit tab bar (Liquid Glass on iOS 26) with a split
/// search-role tab; the pages it switches between are plain Flutter.
///
/// Scrolling here is Flutter's, so the native collapse/minimize animations
/// don't trigger — that's what `CupertinoNativeScaffold` is for.
class StandaloneTabBarDemoPage extends StatefulWidget {
  const StandaloneTabBarDemoPage({super.key});

  @override
  State<StandaloneTabBarDemoPage> createState() =>
      _StandaloneTabBarDemoPageState();
}

class _StandaloneTabBarDemoPageState extends State<StandaloneTabBarDemoPage> {
  String _selectedTab = 'home';

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Tab Bar',
      backgroundColor: CupertinoColors.systemBackground,
      bottomBar: CupertinoNativeTabBar(
        value: _selectedTab,
        scrollEdgeEffect: CupertinoScrollEdgeEffectStyle.soft,
        split: true,
        rightCount: 1,
        tabs: [
          CupertinoNativeTab(
            title: 'Home',
            icon: CupertinoNativeIcon.symbol(CupertinoSymbols.houseFill),
            id: 'home',
          ),
          CupertinoNativeTab(
            title: 'Profile',
            icon: CupertinoNativeIcon.symbol(CupertinoSymbols.personFill),
            id: 'profile',
          ),
          CupertinoNativeTab(
            title: 'Settings',
            icon: CupertinoNativeIcon.symbol(CupertinoSymbols.gear),
            id: 'settings',
          ),
          CupertinoNativeTab(
            title: '',
            icon: CupertinoNativeIcon.symbol(CupertinoSymbols.magnifyingglass),
            id: 'search',
            role: CupertinoNativeTabRole.search,
          ),
        ],
        onChanged: (id) => setState(() => _selectedTab = id),
      ),
      children: [_body()],
    );
  }

  Widget _body() {
    switch (_selectedTab) {
      case 'search':
        return const SearchTabPage();
      case 'profile':
        return const ProfileTabPage();
      case 'settings':
        return const SettingsTabPage();
      default:
        return const HomeTabPage();
    }
  }
}

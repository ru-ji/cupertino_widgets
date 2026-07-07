import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

import 'home_tab_page.dart';
import 'profile_tab_page.dart';
import 'search_tab_page.dart';
import 'settings_tab_page.dart';

/// The standalone native tab bar inside a plain Flutter Scaffold. The bar is a
/// bare UIKit tab bar in a transparent container that floats at its content
/// width; the body is ordinary Flutter content. Scrolling here is Flutter's, so
/// the native collapse/minimize animations don't trigger — that's what
/// `CupertinoNativeScaffold` is for.
///
/// (The standalone native app bar was removed; navigation bars now live only
/// inside `CupertinoNativeScaffold`.)
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
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Standalone Tab Bar')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: padding.bottom + 60),
            child: _body(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: CupertinoNativeTabBar(
              selection: _selectedTab,
              accentColor: Colors.blue,
              scrollEdgeEffect: CupertinoNativeScrollEdgeEffect.soft,
              split: true,
              rightCount: 1,
              tabs: const [
                CupertinoNativeTab(
                  title: 'Home',
                  icon: CupertinoNativeIcon.named('house.fill'),
                  id: 'home',
                ),
                CupertinoNativeTab(
                  title: 'Profile',
                  icon: CupertinoNativeIcon.named('person.fill'),
                  id: 'profile',
                ),
                CupertinoNativeTab(
                  title: 'Settings',
                  icon: CupertinoNativeIcon.named('gear'),
                  id: 'settings',
                ),
                CupertinoNativeTab(
                  title: '',
                  icon: CupertinoNativeIcon.named('magnifyingglass'),
                  id: 'search',
                  role: CupertinoNativeTabRole.search,
                ),
              ],
              onSelectionChanged: (id) => setState(() => _selectedTab = id),
            ),
          ),
        ],
      ),
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

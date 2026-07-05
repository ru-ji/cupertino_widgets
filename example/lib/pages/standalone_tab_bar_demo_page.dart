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
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: padding.bottom + 60),
              child: _body(),
            ),
          ),
          // Floating native tab bar, split so Search detaches on the right.
          // Sits low like the system pill: a small gap above the home
          // indicator instead of a full safe-area inset.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: padding.bottom > 0 ? padding.bottom - 18 : 12),
              child: CupertinoNativeTabBar(
                selection: _selectedTab,
                accentColor: Colors.blue,
                split: true,
                rightCount: 1,
                tabs: const [
                  CupertinoNativeTab(
                      title: 'Home', systemImage: 'house.fill', id: 'home'),
                  CupertinoNativeTab(
                      title: 'Profile',
                      systemImage: 'person.fill',
                      id: 'profile'),
                  CupertinoNativeTab(
                      title: 'Settings', systemImage: 'gear', id: 'settings'),
                  CupertinoNativeTab(
                      title: '',
                      systemImage: 'magnifyingglass',
                      id: 'search',
                      role: CupertinoNativeTabRole.search),
                ],
                onSelectionChanged: (id) => setState(() => _selectedTab = id),
              ),
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

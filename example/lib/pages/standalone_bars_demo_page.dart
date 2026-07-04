import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

import 'home_tab_page.dart';
import 'profile_tab_page.dart';
import 'search_tab_page.dart';
import 'settings_tab_page.dart';

/// The app bar and tab bar used individually inside a standard Flutter
/// Scaffold. The body fills the whole screen (Stack + extendBodyBehindAppBar)
/// and stays visible through/around the bars: both are bare UIKit bars in
/// transparent containers, and the tab bar floats at its content width.
/// Scrolling here is Flutter's, so the native collapse/minimize animations
/// don't trigger — that's what CupertinoNativeScaffold is for.
class StandaloneBarsDemoPage extends StatefulWidget {
  const StandaloneBarsDemoPage({super.key});

  @override
  State<StandaloneBarsDemoPage> createState() => _StandaloneBarsDemoPageState();
}

class _StandaloneBarsDemoPageState extends State<StandaloneBarsDemoPage> {
  String _selectedTab = 'home';
  String _lastAction = 'None';

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CupertinoNativeAppBar(
        title: 'Standalone Bars',
        leading: const [
          CupertinoNativeBarItem(
              icon: CupertinoNativeSymbol('chevron.left'), actionId: 'back'),
        ],
        trailing: const [
          // A grouped pair (one shared capsule)...
          CupertinoNativeBarItemGroup(items: [
            CupertinoNativeBarItem(
                icon: CupertinoNativeSymbol('plus'), actionId: 'add'),
            CupertinoNativeBarItem(
                icon: CupertinoNativeSymbol('ellipsis.circle'),
                actionId: 'more'),
          ]),
          // ...and a separate button (own capsule).
          CupertinoNativeBarItem(
              icon: CupertinoNativeSymbol('square.and.arrow.up'),
              actionId: 'share'),
        ],
        onAction: (id) {
          if (id == 'back') {
            Navigator.of(context).pop();
            return;
          }
          setState(() => _lastAction = id);
        },
      ),
      body: Stack(
        children: [
          // Full-screen Flutter content, scrolling behind both bars.
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: padding.top + 44,
                bottom: padding.bottom + 60,
              ),
              child: Column(
                children: [
                  Text('Last bar action: $_lastAction'),
                  _body(),
                ],
              ),
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

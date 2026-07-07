import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

/// Full native SwiftUI scaffold: large title that collapses on scroll,
/// grouped toolbar items, a tab bar with a search-role tab and
/// minimize-on-scroll (iOS 26), soft scroll edge effect, and native push/pop
/// transitions (see ScaffoldHomeBody). Bodies come from `scaffoldRoutes()`
/// via `CupertinoNativeScaffold.maybeRun` in main() — no entry point needed.
class NativeScaffoldDemoPage extends StatelessWidget {
  const NativeScaffoldDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupertinoNativeScaffold(
        scrollEdgeEffect: CupertinoNativeScrollEdgeEffect.soft,
        appBar: CupertinoNativeAppBar(
          title: 'Library',
          titleDisplayMode: CupertinoNativeToolbarTitleDisplayMode.large,
          trailing: [
            // Each CupertinoNativeBarItem gets its own glass capsule (iOS 26).
            // Wrap multiple items in CupertinoNativeBarItemGroup to share one capsule.
            CupertinoNativeBarItem(
                icon: CupertinoNativeIcon.symbol(CupertinoSymbols.plus),
                actionId: 'add'),
            CupertinoNativeBarItem(
                icon: CupertinoNativeIcon.flutter(CupertinoIcons.ellipsis_circle),
                actionId: 'more'),
          ],
        ),
        tabBar: const CupertinoNativeTabBar(
          selection: 'home',
          minimizeBehavior: CupertinoNativeTabBarMinimizeBehavior.onScrollDown,
          // iOS 26 bottom accessory (a persistent bar above the tab bar). It
          // shows its subtitle only in the system's `.expanded` placement.
          accessory: CupertinoNativeTabBarAccessory(
            title: 'Now Playing',
            subtitle: 'Swift Playgrounds — Track 3',
            icon: CupertinoNativeIcon.named('music.note'),
            actionId: 'accessory',
          ),
          tabs: [
            CupertinoNativeTab(
              title: 'Home',
              icon: CupertinoNativeIcon.named('house.fill'),
              id: 'home',
            ),
            CupertinoNativeTab(
              title: 'Search',
              icon: CupertinoNativeIcon.named('magnifyingglass'),
              id: 'search',
              role: CupertinoNativeTabRole.search,
              // The search-role tab presents itself as a native search field.
              search: CupertinoNativeSearchField(
                placeholder: 'Search languages',
              ),
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
          ],
        ),
        onBarAction: (route, actionId) {
          debugPrint('Scaffold bar action on $route: $actionId');
        },
        onTabChanged: (id) => debugPrint('Scaffold tab changed: $id'),
        onRouteChanged: (routes) =>
            debugPrint('Scaffold stack: ${routes.join(' > ')}'),
      ),
    );
  }
}

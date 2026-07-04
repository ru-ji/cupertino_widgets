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
        appBar: const CupertinoNativeAppBar(
          title: 'Library',
          largeTitle: true,
          trailing: [
            // One shared glass capsule with two buttons:
            CupertinoNativeBarItemGroup(items: [
              CupertinoNativeBarItem(
                  icon: CupertinoNativeSymbol('plus'), actionId: 'add'),
              CupertinoNativeBarItem(
                  icon: CupertinoNativeSymbol('ellipsis.circle'),
                  actionId: 'more'),
            ]),
          ],
        ),
        tabBar: const CupertinoNativeTabBar(
          selection: 'home',
          minimizeBehavior: CupertinoNativeTabBarMinimizeBehavior.onScrollDown,
          tabs: [
            CupertinoNativeTab(
              title: 'Home',
              systemImage: 'house.fill',
              id: 'home',
            ),
            CupertinoNativeTab(
              title: 'Search',
              systemImage: 'magnifyingglass',
              id: 'search',
              role: CupertinoNativeTabRole.search,
            ),
            CupertinoNativeTab(
              title: 'Profile',
              systemImage: 'person.fill',
              id: 'profile',
            ),
            CupertinoNativeTab(
              title: 'Settings',
              systemImage: 'gear',
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

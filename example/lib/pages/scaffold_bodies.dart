import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

/// Body for the scaffold's home tab. Runs in its own FlutterEngine inside the
/// native ScrollView — scrolling this content collapses the large title and
/// (with minimizeBehavior) shrinks the tab bar, all natively.
///
/// Note: use plain Flutter widgets in scaffold bodies. Platform-view widgets
/// (CupertinoNativeButton, ...) cannot render here because the body engine
/// itself already lives inside a native platform view.
class ScaffoldHomeBody extends StatelessWidget {
  const ScaffoldHomeBody({super.key});

  static const _colors = [
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.orange,
    Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        FilledButton.icon(
          icon: const Icon(Icons.chevron_right),
          label: const Text('Open Details'),
          onPressed: () {
            CupertinoNativeScaffold.push(
              CupertinoNativeScaffoldPage(
                route: 'details',
                appBar: CupertinoNativeAppBar(
                  title: 'Details',
                  trailing: [
                    CupertinoNativeBarItem(
                      icon: CupertinoNativeIcon.symbol(
                          CupertinoSymbols.squareAndArrowUp),
                      actionId: 'share_details',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'This Flutter content lives inside the native SwiftUI ScrollView. '
            'Scroll it: the large title collapses and the tab bar minimizes — '
            'both driven by native scrolling.',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        // Long, obviously-scrollable Flutter content.
        for (var i = 0; i < 30; i++)
          Container(
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _colors[i % _colors.length].withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Flutter row $i',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
      ],
    );
  }
}

/// Body for the pushed detail page — also its own engine. The native back
/// button and back-swipe pop it; the button here pops programmatically.
class ScaffoldDetailsBody extends StatelessWidget {
  const ScaffoldDetailsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.description, size: 64, color: Colors.indigo),
          const SizedBox(height: 16),
          const Text(
            'Detail Page',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This page was pushed onto the native SwiftUI NavigationStack. '
            'The slide transition, the toolbar morph, and the back-swipe '
            'gesture are all system behavior.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.chevron_left),
            label: const Text('Pop'),
            onPressed: () => CupertinoNativeScaffold.pop(),
          ),
        ],
      ),
    );
  }
}

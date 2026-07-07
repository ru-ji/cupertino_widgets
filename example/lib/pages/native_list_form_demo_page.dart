import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

/// Demonstrates the native SwiftUI `List` (with sections) and `Form` (with
/// sections) wrapped as Flutter widgets. Both self-size to their content, so
/// they drop straight into a scrolling Column.
class NativeListFormDemoPage extends StatefulWidget {
  const NativeListFormDemoPage({super.key});

  @override
  State<NativeListFormDemoPage> createState() => _NativeListFormDemoPageState();
}

class _NativeListFormDemoPageState extends State<NativeListFormDemoPage> {
  String _lastTap = 'None';
  bool _wifi = true;
  bool _bluetooth = false;
  bool _airplane = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Native List & Form')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('CupertinoNativeList',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Text('  Last tapped: $_lastTap',
              style: const TextStyle(color: Colors.grey)),

          // A native inset-grouped List with two sections.
          CupertinoNativeList(
            style: CupertinoNativeListStyle.insetGrouped,
            onRowTap: (id) => setState(() => _lastTap = id),
            sections: [
              CupertinoNativeListSection(
                header: 'Languages',
                footer: 'Tap a row — the id is reported to Flutter.',
                rows: [
                  CupertinoNativeListRow(
                    id: 'swift',
                    title: 'Swift',
                    subtitle: 'Apple platforms',
                    icon: CupertinoNativeIcon.named('swift',
                        color: Colors.orange),
                    showChevron: true,
                  ),
                  CupertinoNativeListRow(
                    id: 'dart',
                    title: 'Dart',
                    subtitle: 'Flutter',
                    icon: CupertinoNativeIcon.flutter(CupertinoIcons.bolt_fill,
                        color: Colors.blue),
                    showChevron: true,
                  ),
                  const CupertinoNativeListRow(
                    id: 'python',
                    title: 'Python',
                    value: 'v3.12',
                    showChevron: true,
                  ),
                ],
              ),
              const CupertinoNativeListSection(
                header: 'About',
                rows: [
                  CupertinoNativeListRow(id: 'version', title: 'Version', value: '1.0.0'),
                  CupertinoNativeListRow(
                    id: 'source',
                    title: 'View Source',
                    type: CupertinoNativeListRowType.button,
                  ),
                ],
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('CupertinoNativeForm',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          // A native Form with a section of toggle rows.
          CupertinoNativeForm(
            onToggle: (id, value) {
              setState(() {
                switch (id) {
                  case 'wifi':
                    _wifi = value;
                    break;
                  case 'bluetooth':
                    _bluetooth = value;
                    break;
                  case 'airplane':
                    _airplane = value;
                    break;
                }
              });
            },
            sections: [
              CupertinoNativeListSection(
                header: 'Connectivity',
                footer: 'Wi-Fi: $_wifi · Bluetooth: $_bluetooth · '
                    'Airplane: $_airplane',
                rows: [
                  CupertinoNativeListRow(
                    id: 'airplane',
                    title: 'Airplane Mode',
                    icon: const CupertinoNativeIcon.named('airplane'),
                    type: CupertinoNativeListRowType.toggle,
                    toggleValue: _airplane,
                  ),
                  CupertinoNativeListRow(
                    id: 'wifi',
                    title: 'Wi-Fi',
                    icon: const CupertinoNativeIcon.named('wifi'),
                    type: CupertinoNativeListRowType.toggle,
                    toggleValue: _wifi,
                  ),
                  CupertinoNativeListRow(
                    id: 'bluetooth',
                    title: 'Bluetooth',
                    icon: const CupertinoNativeIcon.named('dot.radiowaves.left.and.right'),
                    type: CupertinoNativeListRowType.toggle,
                    toggleValue: _bluetooth,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

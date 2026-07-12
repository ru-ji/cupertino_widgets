import 'package:flutter/cupertino.dart';
import 'package:cupertino_widgets/cupertino_widgets.dart';

import '../widgets/settings_ui.dart';

/// [CupertinoNativeList] and [CupertinoNativeForm] as a Settings clone. Both
/// are rendered natively (SwiftUI-style inset-grouped sections) and self-size,
/// so they drop straight into this Flutter scroll view. Section corners match
/// the running iOS version automatically (26pt on iOS 26+).
class NativeListFormDemoPage extends StatefulWidget {
  const NativeListFormDemoPage({super.key});

  @override
  State<NativeListFormDemoPage> createState() => _NativeListFormDemoPageState();
}

class _NativeListFormDemoPageState extends State<NativeListFormDemoPage> {
  String _lastTap = 'none';
  bool _airplane = false;
  bool _wifi = true;
  bool _bluetooth = true;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'List & Form',
      children: [
        // ---- CupertinoNativeList: navigation-style rows -------------------
        CupertinoNativeList(
          style: CupertinoNativeListStyle.insetGrouped,
          onRowTap: (id) => setState(() => _lastTap = id),
          sections: [
            CupertinoNativeListSection(
              header: 'General',
              footer: 'Native rows: taps report the row id to Flutter '
                  '(last: $_lastTap).',
              rows: [
                CupertinoNativeListRow(
                  id: 'about',
                  title: 'About',
                  icon: CupertinoNativeIcon.symbol(
                      CupertinoSymbols.infoCircleFill,
                      color: CupertinoColors.systemBlue),
                  showChevron: true,
                ),
                CupertinoNativeListRow(
                  id: 'update',
                  title: 'Software Update',
                  value: 'iOS 26.0',
                  icon: CupertinoNativeIcon.symbol(CupertinoSymbols.gear,
                      color: CupertinoColors.systemGrey),
                  showChevron: true,
                ),
                CupertinoNativeListRow(
                  id: 'storage',
                  title: 'iPhone Storage',
                  subtitle: '205 GB of 256 GB used',
                  icon: const CupertinoNativeIcon.named('internaldrive',
                      color: CupertinoColors.systemOrange),
                  showChevron: true,
                ),
                const CupertinoNativeListRow(
                  id: 'legal',
                  title: 'Legal & Regulatory',
                  type: CupertinoNativeListRowType.button,
                ),
              ],
            ),
          ],
        ),

        // ---- CupertinoNativeForm: toggle rows ------------------------------
        CupertinoNativeForm(
          onToggle: (id, value) {
            setState(() {
              switch (id) {
                case 'airplane':
                  _airplane = value;
                case 'wifi':
                  _wifi = value;
                case 'bluetooth':
                  _bluetooth = value;
              }
            });
          },
          sections: [
            CupertinoNativeListSection(
              header: 'Connectivity',
              footer: 'Native Form with toggle rows — '
                  'Wi-Fi ${_wifi ? 'on' : 'off'} · '
                  'Bluetooth ${_bluetooth ? 'on' : 'off'} · '
                  'Airplane ${_airplane ? 'on' : 'off'}.',
              rows: [
                CupertinoNativeListRow(
                  id: 'airplane',
                  title: 'Airplane Mode',
                  icon: const CupertinoNativeIcon.named('airplane',
                      color: CupertinoColors.systemOrange),
                  type: CupertinoNativeListRowType.toggle,
                  toggleValue: _airplane,
                ),
                CupertinoNativeListRow(
                  id: 'wifi',
                  title: 'Wi-Fi',
                  subtitle: 'FlutterNet',
                  icon: CupertinoNativeIcon.symbol(CupertinoSymbols.wifi,
                      color: CupertinoColors.systemBlue),
                  type: CupertinoNativeListRowType.toggle,
                  toggleValue: _wifi,
                ),
                CupertinoNativeListRow(
                  id: 'bluetooth',
                  title: 'Bluetooth',
                  icon: const CupertinoNativeIcon.named(
                      'dot.radiowaves.left.and.right',
                      color: CupertinoColors.systemBlue),
                  type: CupertinoNativeListRowType.toggle,
                  toggleValue: _bluetooth,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

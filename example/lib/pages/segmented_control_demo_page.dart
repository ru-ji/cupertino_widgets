import 'package:flutter/cupertino.dart';
import 'package:cupertino_widgets/cupertino_widgets.dart';

import '../widgets/settings_ui.dart';

/// [CupertinoNativeSegmentedControl] presented as a "Display & Brightness"
/// style settings page.
class SegmentedControlDemoPage extends StatefulWidget {
  const SegmentedControlDemoPage({super.key});

  @override
  State<SegmentedControlDemoPage> createState() =>
      _SegmentedControlDemoPageState();
}

class _SegmentedControlDemoPageState extends State<SegmentedControlDemoPage> {
  static const _appearances = ['Light', 'Dark', 'Auto'];
  static const _ranges = ['Day', 'Week', 'Month', 'Year'];
  static const _textSizes = ['S', 'M', 'L', 'XL'];

  int _appearance = 2;
  int _range = 1;
  int _textSize = 1;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Segmented Control',
      children: [
        SettingsSection(
          header: 'Appearance',
          footer:
              'A native UISegmentedControl — the sliding selection is the '
              'system animation. Selected: ${_appearances[_appearance]}.',
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoNativeSegmentedControl(
                children: _appearances,
                groupValue: _appearance,
                onChanged: (v) => setState(() => _appearance = v),
              ),
            ),
          ],
        ),
        SettingsSection(
          header: 'Calendar',
          footer: 'Showing your schedule by ${_ranges[_range].toLowerCase()}.',
          children: [
            SettingsRow(title: 'View', value: _ranges[_range]),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CupertinoNativeSegmentedControl(
                children: _ranges,
                groupValue: _range,
                onChanged: (v) => setState(() => _range = v),
              ),
            ),
          ],
        ),
        SettingsSection(
          header: 'Text Size',
          footer: 'color tints the selected segment.',
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoNativeSegmentedControl(
                children: _textSizes,
                groupValue: _textSize,
                activeColor: CupertinoColors.systemPurple,
                onChanged: (v) => setState(() => _textSize = v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

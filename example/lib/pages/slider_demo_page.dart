import 'package:flutter/cupertino.dart';
import 'package:cupertino_widgets/cupertino_widgets.dart';

import '../widgets/settings_ui.dart';

/// [CupertinoNativeSlider] presented as a "Sounds & Haptics"-style settings
/// page: each card holds a label row with the live value and the native
/// UISlider right underneath.
class SliderDemoPage extends StatefulWidget {
  const SliderDemoPage({super.key});

  @override
  State<SliderDemoPage> createState() => _SliderDemoPageState();
}

class _SliderDemoPageState extends State<SliderDemoPage> {
  double _volume = 0.55;
  double _brightness = 0.8;
  double _alertVolume = 0.6;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Slider',
      children: [
        SettingsSection(
          header: 'Ringtone and Alerts',
          footer:
              'The slider is a native UISlider — drag it and the value '
              'streams back to Flutter live.',
          children: [
            _SliderTile(
              label: 'Volume',
              value: '${(_volume * 100).round()}%',
              slider: CupertinoNativeSlider(
                value: _volume,
                onChanged: (v) => setState(() => _volume = v),
              ),
            ),
          ],
        ),
        SettingsSection(
          header: 'Display',
          footer: 'activeColor tints the filled track.',
          children: [
            _SliderTile(
              label: 'Brightness',
              value: '${(_brightness * 100).round()}%',
              slider: CupertinoNativeSlider(
                value: _brightness,
                activeColor: CupertinoColors.systemOrange,
                onChanged: (v) => setState(() => _brightness = v),
              ),
            ),
          ],
        ),
        SettingsSection(
          header: 'Alert Volume',
          footer: 'divisions: 10 snaps the thumb to discrete steps.',
          children: [
            _SliderTile(
              label: 'Alerts',
              value: '${(_alertVolume * 100).round()}%',
              slider: CupertinoNativeSlider(
                value: _alertVolume,
                divisions: 10,
                onChanged: (v) => setState(() => _alertVolume = v),
              ),
            ),
          ],
        ),
        const SettingsSection(
          header: 'Managed',
          footer: 'onChanged: null renders the native disabled appearance.',
          children: [
            _SliderTile(
              label: 'Media Volume',
              value: 'Locked',
              slider: CupertinoNativeSlider(value: 0.35, onChanged: null),
            ),
          ],
        ),
      ],
    );
  }
}

/// A settings cell with a title/value row and a full-width slider below it.
class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.slider,
  });

  final String label;
  final String value;
  final Widget slider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: rowTitleStyle(context))),
              Text(value, style: rowValueStyle(context)),
            ],
          ),
          const SizedBox(height: 4),
          slider,
        ],
      ),
    );
  }
}

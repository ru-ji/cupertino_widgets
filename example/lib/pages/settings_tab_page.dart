import 'package:flutter/cupertino.dart';

import '../widgets/settings_ui.dart';

/// Settings tab body — shared with the native scaffold, so drawn Flutter
/// widgets only (no platform views).
class SettingsTabPage extends StatelessWidget {
  const SettingsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsSection(
          cardColor: CupertinoColors.systemGrey6,
          header: 'Preferences',
          children: [
            SettingsRow(title: 'Notifications', value: 'On', showChevron: true),
            SettingsRow(title: 'Sounds & Haptics', showChevron: true),
            SettingsRow(title: 'Focus', showChevron: true),
          ],
        ),
        SettingsSection(
          cardColor: CupertinoColors.systemGrey6,
          header: 'Privacy',
          children: [
            SettingsRow(title: 'Location Services', value: 'While Using',
                showChevron: true),
            SettingsRow(title: 'Tracking', showChevron: true),
          ],
        ),
        SettingsSection(
          cardColor: CupertinoColors.systemGrey6,
          footer: 'Cupertino Widgets 1.0.0',
          children: [
            SettingsRow(title: 'About', showChevron: true),
            SettingsRow(title: 'Legal & Regulatory', showChevron: true),
          ],
        ),
        SizedBox(height: 24),
      ],
    );
  }
}

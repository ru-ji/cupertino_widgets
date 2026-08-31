import 'package:flutter/cupertino.dart' show CupertinoColors;
import 'package:flutter/widgets.dart';
import 'package:cupertino_widgets/cupertino_widgets.dart';

import '../widgets/settings_ui.dart';

/// Content of the native sheet demo — a "New Event" form. Runs in its own
/// FlutterEngine hosted in the sheet's native ScrollView, so it must be a
/// self-sized Column (same contract as scaffold bodies); the sheet's title,
/// ✕/Add buttons, search field and segmented control are native chrome
/// configured from `CupertinoNativeSheet.show`. Tall on purpose — scroll it
/// under the pinned bar.
class NewEventSheetBody extends StatelessWidget {
  const NewEventSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final background = CupertinoColors.systemGroupedBackground.resolveFrom(
      context,
    );
    final blue = CupertinoColors.activeBlue.resolveFrom(context);

    return ColoredBox(
      color: background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSection(
            children: [
              SettingsRow(title: 'Team Standup'),
              SettingsRow(title: 'Location', value: 'Cupertino HQ'),
            ],
          ),
          const SettingsSection(
            children: [
              SettingsRow(title: 'All-day', value: 'Off'),
              SettingsRow(title: 'Starts', value: 'Jul 12, 9:41 AM'),
              SettingsRow(title: 'Ends', value: 'Jul 12, 10:00 AM'),
              SettingsRow(
                title: 'Travel Time',
                value: 'None',
                showChevron: true,
              ),
            ],
          ),
          const SettingsSection(
            children: [
              SettingsRow(title: 'Repeat', value: 'Never', showChevron: true),
              SettingsRow(title: 'Calendar', value: 'Work', showChevron: true),
              SettingsRow(title: 'Invitees', value: '3', showChevron: true),
            ],
          ),
          const SettingsSection(
            children: [
              SettingsRow(
                title: 'Alert',
                value: '10 min before',
                showChevron: true,
              ),
              SettingsRow(
                title: 'Second Alert',
                value: 'None',
                showChevron: true,
              ),
              SettingsRow(title: 'Show As', value: 'Busy', showChevron: true),
            ],
          ),
          const SettingsSection(
            footer:
                'This whole form is Flutter inside a real UIKit sheet: '
                'the bar stays pinned while you scroll, and pulling down at '
                'the top drags the sheet itself.',
            children: [
              SettingsRow(title: 'URL', value: 'None'),
              SettingsRow(title: 'Notes', value: 'None'),
              SettingsRow(
                title: 'Attachments',
                value: 'None',
                showChevron: true,
              ),
            ],
          ),
          SettingsSection(
            children: [
              SettingsRow(
                title: 'Dismiss from Flutter',
                titleColor: blue,
                onTap: () => CupertinoNativeSheet.pop(),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

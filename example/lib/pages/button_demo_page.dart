import 'package:flutter/cupertino.dart';
import 'package:cupertino_widgets/cupertino_widgets.dart';

import '../widgets/settings_ui.dart';

/// [CupertinoNativeButton] presented as a contact-card page: real call/message
/// actions up top, then the style, size and shape variations below. All icons
/// are SF Symbols.
class ButtonDemoPage extends StatefulWidget {
  const ButtonDemoPage({super.key});

  @override
  State<ButtonDemoPage> createState() => _ButtonDemoPageState();
}

class _ButtonDemoPageState extends State<ButtonDemoPage> {
  String _lastAction = 'None yet';

  void _did(String action) => setState(() => _lastAction = action);

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Button',
      children: [
        SettingsSection(
          header: 'Contact',
          footer: 'Last action: $_lastAction',
          children: [
            const SettingsRow(
              title: 'Casey Rivera',
              subtitle: 'mobile · +1 (555) 010-9265',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CupertinoNativeButton(
                    title: 'Call',
                    icon: CupertinoNativeIcon.symbol(
                      CupertinoSymbols.phoneFill,
                    ),
                    style: CupertinoNativeButtonStyle.filled,
                    borderShape: CupertinoNativeButtonBorderShape.capsule,
                    controlSize: CupertinoNativeControlSize.large,
                    activeColor: CupertinoColors.systemGreen,
                    onPressed: () => _did('Call'),
                  ),
                  CupertinoNativeButton(
                    title: 'Message',
                    icon: CupertinoNativeIcon.symbol(
                      CupertinoSymbols.messageFill,
                    ),
                    style: CupertinoNativeButtonStyle.tinted,
                    borderShape: CupertinoNativeButtonBorderShape.capsule,
                    controlSize: CupertinoNativeControlSize.large,
                    onPressed: () => _did('Message'),
                  ),
                  CupertinoNativeButton(
                    title: 'Record',
                    icon: CupertinoNativeIcon.symbol(CupertinoSymbols.micFill),
                    style: CupertinoNativeButtonStyle.glass,
                    borderShape: CupertinoNativeButtonBorderShape.circle,
                    labelStyle: CupertinoNativeButtonLabelStyle.iconOnly,
                    controlSize: CupertinoNativeControlSize.large,
                    activeColor: CupertinoColors.systemRed,
                    onPressed: () => _did('Record'),
                  ),
                ],
              ),
            ),
          ],
        ),
        SettingsSection(
          header: 'Styles',
          footer:
              'glass and glassProminent use the iOS 26 Liquid Glass '
              'material.',
          children: [
            _buttonRow(
              'Filled',
              CupertinoNativeButton(
                title: 'Get',
                style: CupertinoNativeButtonStyle.filled,
                onPressed: () => _did('Filled'),
              ),
            ),
            _buttonRow(
              'Tinted',
              CupertinoNativeButton(
                title: 'Follow',
                style: CupertinoNativeButtonStyle.tinted,
                onPressed: () => _did('Tinted'),
              ),
            ),
            _buttonRow(
              'Glass',
              CupertinoNativeButton(
                title: 'Share',
                icon: CupertinoNativeIcon.symbol(
                  CupertinoSymbols.squareAndArrowUp,
                ),
                style: CupertinoNativeButtonStyle.glass,
                onPressed: () => _did('Glass'),
              ),
            ),
            _buttonRow(
              'Glass Prominent',
              CupertinoNativeButton(
                title: 'Continue',
                style: CupertinoNativeButtonStyle.glassProminent,
                activeColor: CupertinoColors.systemPurple,
                onPressed: () => _did('Glass Prominent'),
              ),
            ),
            _buttonRow(
              'Plain',
              CupertinoNativeButton(
                title: 'Not Now',
                style: CupertinoNativeButtonStyle.plain,
                onPressed: () => _did('Plain'),
              ),
            ),
          ],
        ),
        SettingsSection(
          header: 'Sizes',
          children: [
            _buttonRow(
              'Large',
              CupertinoNativeButton(
                title: 'Large',
                style: CupertinoNativeButtonStyle.tinted,
                controlSize: CupertinoNativeControlSize.large,
                onPressed: () => _did('Large'),
              ),
            ),
            _buttonRow(
              'Regular',
              CupertinoNativeButton(
                title: 'Regular',
                style: CupertinoNativeButtonStyle.tinted,
                onPressed: () => _did('Regular'),
              ),
            ),
            _buttonRow(
              'Small',
              CupertinoNativeButton(
                title: 'Small',
                style: CupertinoNativeButtonStyle.tinted,
                controlSize: CupertinoNativeControlSize.small,
                onPressed: () => _did('Small'),
              ),
            ),
            _buttonRow(
              'Mini',
              CupertinoNativeButton(
                title: 'Mini',
                style: CupertinoNativeButtonStyle.tinted,
                controlSize: CupertinoNativeControlSize.mini,
                onPressed: () => _did('Mini'),
              ),
            ),
          ],
        ),
        SettingsSection(
          header: 'Full Width',
          footer:
              'expand: true fills the available width — the standard '
              'bottom-of-sheet call to action.',
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoNativeButton(
                title: 'Sign Out',
                style: CupertinoNativeButtonStyle.filled,
                controlSize: CupertinoNativeControlSize.large,
                activeColor: CupertinoColors.systemRed,
                expand: true,
                onPressed: () => _did('Sign Out'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buttonRow(String label, Widget button) {
    return SettingsRow(title: label, trailing: button);
  }
}

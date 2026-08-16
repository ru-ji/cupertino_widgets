import 'package:flutter/cupertino.dart';
import 'package:cupertino_widgets/cupertino_widgets.dart';

import '../widgets/settings_ui.dart';

/// [CupertinoNativeMenu] presented as a Files-style page: a text-anchored
/// menu, an icon-anchored menu, and a submenu with a live toggle. The popup
/// itself is a real UIMenu with SF Symbol items.
class MenuDemoPage extends StatefulWidget {
  const MenuDemoPage({super.key});

  @override
  State<MenuDemoPage> createState() => _MenuDemoPageState();
}

class _MenuDemoPageState extends State<MenuDemoPage> {
  String _lastAction = 'None yet';
  bool _showHidden = false;

  List<CupertinoNativeMenuItem> get _fileMenuItems => [
    const CupertinoNativeMenuSection(
      items: [
        CupertinoNativeMenuAction(
          title: 'New File',
          systemImage: 'doc',
          actionId: 'new_file',
        ),
        CupertinoNativeMenuAction(
          title: 'New Folder',
          systemImage: 'folder',
          actionId: 'new_folder',
        ),
      ],
    ),
    const CupertinoNativeMenuSection(
      items: [
        CupertinoNativeMenuAction(
          title: 'Rename',
          systemImage: 'pencil',
          actionId: 'rename',
        ),
        CupertinoNativeMenuAction(
          title: 'Delete',
          systemImage: 'trash',
          isDestructive: true,
          actionId: 'delete',
        ),
      ],
    ),
    CupertinoNativeSubmenu(
      title: 'View',
      systemImage: 'eye',
      items: [
        CupertinoNativeMenuToggle(
          title: 'Show Hidden Files',
          value: _showHidden,
          actionId: 'toggle_hidden',
          systemImage: 'eye.slash',
        ),
        const CupertinoNativeMenuAction(
          title: 'Reset View',
          actionId: 'reset_view',
        ),
      ],
    ),
  ];

  void _onAction(String id, Object? value) {
    setState(() {
      if (id == 'toggle_hidden') {
        _showHidden = value as bool;
        _lastAction = 'Show hidden: $_showHidden';
      } else {
        _lastAction = id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Popup Menu',
      children: [
        SettingsSection(
          header: 'Anchors',
          footer: 'Last action: $_lastAction',
          children: [
            SettingsRow(
              title: 'Text button',
              trailing: CupertinoNativeMenu(
                title: 'Actions',
                style: CupertinoNativeButtonStyle.plain,
                items: _fileMenuItems,
                onAction: _onAction,
              ),
            ),
            SettingsRow(
              title: 'Icon button',
              trailing: CupertinoNativeMenu(
                title: '',
                systemImage: 'ellipsis.circle',
                style: CupertinoNativeButtonStyle.plain,
                items: _fileMenuItems,
                onAction: _onAction,
              ),
            ),
            SettingsRow(
              title: 'Glass button',
              subtitle: 'iOS 26 Liquid Glass anchor',
              trailing: CupertinoNativeMenu(
                title: 'Options',
                systemImage: 'slider.horizontal.3',
                style: CupertinoNativeButtonStyle.glassProminent,
                activeColor: CupertinoColors.systemPurple,
                items: _fileMenuItems,
                onAction: _onAction,
              ),
            ),
          ],
        ),
        const SettingsSection(
          header: 'About',
          footer:
              'The popup is a native UIMenu: sections, SF Symbol item '
              'icons, a destructive action, a submenu and a checkable toggle '
              'that reports back to Flutter.',
          children: [SettingsRow(title: 'Menu items', value: '6 + submenu')],
        ),
      ],
    );
  }
}

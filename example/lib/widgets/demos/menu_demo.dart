import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

/// Showcases [CupertinoNativeMenu]: sections, a submenu, and a menu toggle
/// that mirrors the map-enabled state from [ToggleDemo].
class MenuDemo extends StatelessWidget {
  const MenuDemo({
    super.key,
    required this.isMapEnabled,
    required this.onMapEnabledChanged,
    required this.onAction,
  });

  final bool isMapEnabled;
  final ValueChanged<bool> onMapEnabledChanged;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return CupertinoNativeMenu(
      title: "Options",
      systemImage: "ellipsis.circle",
      style: CupertinoNativeButtonStyle.glassProminent,
      color: Colors.purple,
      textStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        color: Colors.black,
      ),
      items: [
        const CupertinoNativeMenuSection(
          items: [
            CupertinoNativeMenuAction(
              title: "Share",
              systemImage: "square.and.arrow.up",
              actionId: "share",
            ),
            CupertinoNativeMenuAction(
              title: "Copy",
              systemImage: "doc.on.doc",
              actionId: "copy",
            ),
          ],
        ),
        const CupertinoNativeMenuSection(
          items: [
            CupertinoNativeMenuAction(
              title: "Show Alert",
              systemImage: "exclamationmark.triangle",
              actionId: "alert",
              isDestructive: true,
            ),
            CupertinoNativeMenuAction(
              title: "Delete",
              systemImage: "trash",
              isDestructive: true,
              actionId: "delete",
            ),
          ],
        ),
        CupertinoNativeSubmenu(
          title: "View",
          systemImage: "eye",
          items: [
            CupertinoNativeMenuToggle(
              title: "Show Map",
              value: isMapEnabled,
              actionId: "toggle_map",
              systemImage: "map",
            ),
            const CupertinoNativeMenuAction(
              title: "Reset View",
              actionId: "reset_view",
            ),
          ],
        ),
      ],
      onAction: (id, value) {
        if (id == 'toggle_map') {
          final enabled = value as bool;
          onMapEnabledChanged(enabled);
          onAction('Map Enabled: $enabled');
        } else {
          onAction('Selected: $id');
        }
        debugPrint("Action: $id, Value: $value");
      },
    );
  }
}

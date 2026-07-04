import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

/// Showcases [CupertinoNativeToggle]: a plain switch and a labeled, styled one.
class ToggleDemo extends StatelessWidget {
  const ToggleDemo({
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
    return Column(
      children: [
        CupertinoNativeToggle(
          value: isMapEnabled,
          label: "Map Enabled",
          activeColor: Colors.blue,
          onChanged: (v) {
            onMapEnabledChanged(v);
            onAction("Toggle: $v");
          },
        ),
        CupertinoNativeToggle(
          value: !isMapEnabled,
          activeColor: Colors.red,
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
          onChanged: (v) {
            // Just flipping the same state for demo purposes.
            onMapEnabledChanged(!v);
            onAction("Silent Toggle: $v");
          },
        ),
      ],
    );
  }
}

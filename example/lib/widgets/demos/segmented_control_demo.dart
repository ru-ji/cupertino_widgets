import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

/// Showcases [CupertinoNativeSegmentedControl].
class SegmentedControlDemo extends StatelessWidget {
  const SegmentedControlDemo({super.key, required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: CupertinoNativeSegmentedControl(
        // Should be stateful in real usage, simplified for static UI example.
        groupValue: 0,
        children: const ["Day", "Week", "Month", "Year"],
        onValueChanged: (v) {
          onAction("Segment: $v");
        },
      ),
    );
  }
}

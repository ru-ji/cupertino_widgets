import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

/// Showcases [CupertinoNativeButton]: styles, control sizes/expand,
/// border-shape variations (circle, capsule), and icons from both SF Symbols
/// and Flutter [IconData].
class ButtonDemo extends StatelessWidget {
  const ButtonDemo({super.key, required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Native Buttons"),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Use Expanded to take remaining width in a Row.
            Expanded(
              child: CupertinoNativeButton(
                title: "Filled",
                color: Colors.red,
                style: CupertinoNativeButtonStyle.filled,
                controlSize: CupertinoNativeControlSize.large,
                expand: true,
                systemImage: "star.fill",
                onPressed: () => onAction("Filled Button"),
              ),
            ),
            CupertinoNativeButton(
              title: "Tinted",
              textStyle: const TextStyle(fontSize: 20),
              style: CupertinoNativeButtonStyle.tinted,
              onPressed: () => onAction("Tinted Button"),
            ),
            CupertinoNativeButton(
              title: "Glass",
              style: CupertinoNativeButtonStyle.glassProminent,
              color: Colors.purple,
              onPressed: () => onAction("Glass Button"),
            ),
            CupertinoNativeButton(
              title: "Plain",
              style: CupertinoNativeButtonStyle.plain,
              onPressed: () => onAction("Plain Button"),
            ),
          ],
        ),
        const Text("Control Size & Expand"),
        Column(
          children: [
            CupertinoNativeButton(
              title: "Large Expanded",
              style: CupertinoNativeButtonStyle.filled,
              controlSize: CupertinoNativeControlSize.large,
              expand: true,
              onPressed: () {},
            ),
            CupertinoNativeButton(
              title: "Small Capsule",
              style: CupertinoNativeButtonStyle.tinted,
              controlSize: CupertinoNativeControlSize.small,
              onPressed: () {},
            ),
            CupertinoNativeButton(
              title: "Mini",
              style: CupertinoNativeButtonStyle.tinted,
              controlSize: CupertinoNativeControlSize.mini,
              onPressed: () {},
            ),
          ],
        ),
        const Text(
          "Glass Circle Interface",
          style: TextStyle(backgroundColor: Colors.red),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoNativeButton(
              title: "Rec",
              systemImage: "mic.fill",
              style: CupertinoNativeButtonStyle.glass,
              borderShape: CupertinoNativeButtonBorderShape.circle,
              labelStyle: CupertinoNativeButtonLabelStyle.iconOnly,
              controlSize: CupertinoNativeControlSize.large,
              color: Colors.red,
              onPressed: () => onAction("Circle Mic Record"),
            ),
            const SizedBox(width: 20),
            CupertinoNativeButton(
              title: "Call",
              systemImage: "phone.fill",
              style: CupertinoNativeButtonStyle.filled,
              borderShape: CupertinoNativeButtonBorderShape.capsule,
              controlSize: CupertinoNativeControlSize.large,
              color: Colors.green,
              width: 120,
              height: 50,
              onPressed: () => onAction("Call Capsule"),
            ),
          ],
        ),
        const Text("Icons: SF Symbol enum vs Flutter IconData"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Typed SF Symbol with a hierarchical rendering mode.
            CupertinoNativeButton(
              title: "Star",
              icon: CupertinoNativeIcon.symbol(
                CupertinoSymbols.starFill,
                renderingMode: CupertinoSymbolRenderingMode.hierarchical,
              ),
              style: CupertinoNativeButtonStyle.tinted,
              color: Colors.orange,
              onPressed: () => onAction("SF Symbol Star"),
            ),
            const SizedBox(width: 12),
            // A Flutter Cupertino IconData rendered natively via its font.
            CupertinoNativeButton(
              title: "Heart",
              icon: CupertinoNativeIcon.flutter(CupertinoIcons.heart_fill),
              style: CupertinoNativeButtonStyle.tinted,
              color: Colors.pink,
              onPressed: () => onAction("Flutter Cupertino Heart"),
            ),
            const SizedBox(width: 12),
            // A Material IconData rendered natively; icon-only.
            CupertinoNativeButton(
              title: "Favorite",
              icon: CupertinoNativeIcon.flutter(Icons.favorite),
              labelStyle: CupertinoNativeButtonLabelStyle.iconOnly,
              style: CupertinoNativeButtonStyle.filled,
              borderShape: CupertinoNativeButtonBorderShape.circle,
              controlSize: CupertinoNativeControlSize.large,
              color: Colors.red,
              onPressed: () => onAction("Material Favorite"),
            ),
          ],
        ),
      ],
    );
  }
}

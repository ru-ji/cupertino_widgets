import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

/// Showcases [CupertinoNativeAlert].
class AlertDemo extends StatelessWidget {
  const AlertDemo({super.key, required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showAlert(),
      child: const Text("Show Native Alert"),
    );
  }

  void _showAlert() {
    CupertinoNativeAlert.show(
      title: "Mobile Data is Off",
      message: "Turn on mobile data or start using Wi-Fi to access data.",
      actions: [
        CupertinoNativeAlertAction(
          title: "Settings",
          onPressed: () => onAction("Alert: Settings"),
        ),
        CupertinoNativeAlertAction(
          title: "OK",
          isDestructive: true,
          onPressed: () => onAction("Alert: OK"),
        ),
      ],
    );
  }
}

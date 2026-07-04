import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

/// Showcases [CupertinoNativeProgressIndicator]: circular (indeterminate),
/// and linear (determinate, with and without a label).
class ProgressDemo extends StatelessWidget {
  const ProgressDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Native Progress"),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CupertinoNativeProgressIndicator(
              style: CupertinoNativeProgressStyle.circular,
            ),
            CupertinoNativeProgressIndicator(
              style: CupertinoNativeProgressStyle.circular,
              color: Colors.pink,
            ),
          ],
        ),
        Center(
          child: Container(
            color: Colors.red,
            width: 200,
            child: const CupertinoNativeProgressIndicator(
              value: 0.5,
              style: CupertinoNativeProgressStyle.linear,
              color: Colors.green,
            ),
          ),
        ),
        Center(
          child: Container(
            color: Colors.amber,
            child: const CupertinoNativeProgressIndicator(
              value: 10,
              total: 100,
              style: CupertinoNativeProgressStyle.linear,
              label: "Downloading...",
              color: Colors.blue,
            ),
          ),
        ),
        const Text("Tap the icon above to open the native menu"),
      ],
    );
  }
}

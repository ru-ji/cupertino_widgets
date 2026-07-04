import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

/// Showcases [CupertinoNativeSlider].
class SliderDemo extends StatelessWidget {
  const SliderDemo({super.key, required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Slider Value: ${value.toStringAsFixed(2)}'),
        CupertinoNativeSlider(
          value: value,
          min: 0.0,
          max: 1.0,
          activeColor: Colors.purple,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// 地図上の輝度スライダー（右下オーバーレイ）
class BrightnessSliderOverlay extends StatelessWidget {
  const BrightnessSliderOverlay({
    super.key,
    required this.sliderValue,
    required this.onChanged,
  });

  final double sliderValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: SizedBox(
          height: 120,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: sliderValue,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:screen_brightness/screen_brightness.dart';

/// 起動時の画面輝度を取得。失敗時は supported: false。
Future<({double initialBrightness, bool supported})> loadInitialBrightness() async {
  try {
    final value = await ScreenBrightness().current;
    final brightness = value.clamp(0.0, 1.0);
    return (initialBrightness: brightness, supported: true);
  } catch (_) {
    return (initialBrightness: 0.5, supported: false);
  }
}

/// スライダー値（0〜1、0.5＝初期輝度）を実際の輝度（0〜1）に変換する。
double sliderValueToBrightness(double initialBrightness, double sliderValue) {
  if (sliderValue <= 0.5) {
    return initialBrightness * (sliderValue / 0.5);
  }
  return initialBrightness +
      (1.0 - initialBrightness) * ((sliderValue - 0.5) / 0.5);
}

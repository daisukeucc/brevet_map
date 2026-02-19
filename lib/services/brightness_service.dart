import 'package:screen_brightness/screen_brightness.dart';

/// 現在の画面輝度を取得（0.0〜1.0）。失敗時は 0.5 を返す。
Future<double> getCurrentBrightness() async {
  try {
    final value = await ScreenBrightness().current;
    return value.clamp(0.0, 1.0);
  } catch (_) {
    return 0.5;
  }
}

/// アプリの画面輝度を設定（0.0＝最小、1.0＝最大）。アプリ専用でシステム設定は変更しない。
Future<void> setApplicationBrightness(double brightness) async {
  try {
    await ScreenBrightness().setApplicationScreenBrightness(
      brightness.clamp(0.0, 1.0),
    );
  } catch (_) {}
}

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

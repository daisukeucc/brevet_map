import 'package:screen_brightness/screen_brightness.dart';

/// 昼間と判定する開始時刻
const int daytimeStartHour = 6;

/// 昼間と判定する終了時刻
const int daytimeEndHour = 18;

/// 昼間のときの最低輝度
const double minBrightnessDay = 0.01;

/// 夜間のときの最低輝度
const double minBrightnessNight = 0.0;

/// 現在時刻が昼間かどうか（[daytimeStartHour]〜[daytimeEndHour] の範囲内なら true）。
bool isDaytime([DateTime? now]) {
  final t = now ?? DateTime.now();
  return t.hour >= daytimeStartHour && t.hour < daytimeEndHour;
}

/// 昼/夜に応じた画面最低輝度を返す（0.0〜1.0）。LOWモードやスライダー最小値に使う。
double getMinimumBrightness() =>
    isDaytime() ? minBrightnessDay : minBrightnessNight;

/// 現在のアプリ画面輝度を取得（0.0〜1.0）。失敗時は 0.5 を返す。
Future<double> getCurrentBrightness() async {
  try {
    final value = await ScreenBrightness().system;
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

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../constants/map_styles.dart';

// --- 輝度まわり（LOWモード専用）---

/// 昼間と判定する開始時刻
const int daytimeStartHour = 6;

/// 昼間と判定する終了時刻
const int daytimeEndHour = 18;

/// 昼間のときの最低輝度
const double minBrightnessDay = 0.01;

/// 夜間のときの最低輝度
const double minBrightnessNight = 0.0;

bool _isDaytime([DateTime? now]) {
  final t = now ?? DateTime.now();
  return t.hour >= daytimeStartHour && t.hour < daytimeEndHour;
}

double _getMinimumBrightness() =>
    _isDaytime() ? minBrightnessDay : minBrightnessNight;

Future<double> _getCurrentBrightness() async {
  try {
    final value = await ScreenBrightness().system;
    return value.clamp(0.0, 1.0);
  } catch (_) {
    return 0.5;
  }
}

Future<void> _setApplicationBrightness(double brightness) async {
  try {
    await ScreenBrightness().setApplicationScreenBrightness(
      brightness.clamp(0.0, 1.0),
    );
  } catch (_) {}
}

// --- LOWモード ---

/// LOWモード（輝度最小・地図ダーク）の突入・解除を担当する。
/// 復元用の地図スタイル・輝度はこのサービス内で保持する。
class LowModeService {
  int? _savedMapStyle;
  double? _savedBrightness;

  /// 現在LOWモード中か（突入済みで未解除）。
  bool get isInLowMode => _savedMapStyle != null;

  /// LOWモード突入: 現在の地図スタイルと輝度を保存し、輝度を最小・地図をダークにする。
  /// [onMapStyleChanged] に新しい地図スタイル（2）を渡して呼び出す。
  Future<void> enterLowMode(
    GoogleMapController? controller,
    int currentMapStyle,
    void Function(int) onMapStyleChanged,
  ) async {
    _savedMapStyle = currentMapStyle;
    _savedBrightness = await _getCurrentBrightness();
    await _setApplicationBrightness(_getMinimumBrightness());
    if (controller != null) {
      await controller.setMapStyle(mapStyleForMode(2));
    }
    onMapStyleChanged(2);
  }

  /// LOWモード解除: 保存した輝度・地図スタイルに復元する。
  /// [onMapStyleChanged] に復元した地図スタイルを渡して呼び出す。
  /// [saveMapStyleMode] に復元した地図スタイルを渡して永続化する。
  Future<void> leaveLowMode(
    GoogleMapController? controller,
    void Function(int) onMapStyleChanged,
    Future<void> Function(int) saveMapStyleMode,
  ) async {
    if (_savedMapStyle != null) {
      final restored = _savedMapStyle!;
      _savedMapStyle = null;
      if (controller != null) {
        await controller.setMapStyle(mapStyleForMode(restored));
      }
      await saveMapStyleMode(restored);
      onMapStyleChanged(restored);
    }
    if (_savedBrightness != null) {
      await _setApplicationBrightness(_savedBrightness!);
      _savedBrightness = null;
    }
  }
}

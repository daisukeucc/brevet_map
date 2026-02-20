import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'brightness_service.dart';
import '../constants/map_styles.dart';

/// LOWモード（輝度最小・地図ダーク）の突入・解除を担当する。
/// 復元用の地図スタイル・輝度はこのサービス内で保持する。
class LowModeService {
  int? _savedMapStyle;
  double? _savedBrightness;

  /// LOWモード突入: 現在の地図スタイルと輝度を保存し、輝度を最小・地図をダークにする。
  /// [onMapStyleChanged] に新しい地図スタイル（2）を渡して呼び出す。
  Future<void> enterLowMode(
    GoogleMapController? controller,
    int currentMapStyle,
    void Function(int) onMapStyleChanged,
  ) async {
    _savedMapStyle = currentMapStyle;
    _savedBrightness = await getCurrentBrightness();
    await setApplicationBrightness(getMinimumBrightness());
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
      await setApplicationBrightness(_savedBrightness!);
      _savedBrightness = null;
    }
  }
}

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/map_styles.dart';

/// LOWモード（地図ダーク）の突入・解除を担当する。
/// 復元用の地図スタイルはこのサービス内で保持する。
class LowModeService {
  int? _savedMapStyle;

  /// 現在LOWモード中か（突入済みで未解除）。
  bool get isInLowMode => _savedMapStyle != null;

  /// LOWモード突入: 現在の地図スタイルを保存し、地図をダークにする。
  /// [onMapStyleChanged] に新しい地図スタイル（2）を渡して呼び出す。
  Future<void> enterLowMode(
    GoogleMapController? controller,
    int currentMapStyle,
    void Function(int) onMapStyleChanged,
  ) async {
    _savedMapStyle = currentMapStyle;
    if (controller != null) {
      await controller.setMapStyle(mapStyleForMode(2));
    }
    onMapStyleChanged(2);
  }

  /// LOWモード解除: 保存した地図スタイルに復元する。
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
  }
}

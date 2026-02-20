import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'low_mode_service.dart';

/// 一定時間無操作でLOWモードに入り、タッチで解除する処理を担当する。
class IdleLowModeHandler {
  IdleLowModeHandler({
    required this.getController,
    required this.getMapStyleMode,
    required this.onMapStyleChanged,
    required this.saveMapStyleMode,
    required this.lowModeService,
    required this.isLocationStreamActive,
    required this.mounted,
    Duration? idleDuration,
  }) : _idleDuration = idleDuration ?? const Duration(seconds: 300);

  final GoogleMapController? Function() getController;
  final int Function() getMapStyleMode;
  final void Function(int) onMapStyleChanged;
  final Future<void> Function(int) saveMapStyleMode;
  final LowModeService lowModeService;
  final bool Function() isLocationStreamActive;
  final bool Function() mounted;

  final Duration _idleDuration;

  Timer? _timer;
  bool _isInIdleLowMode = false;

  /// 無操作タイマーを開始する。既存のタイマーはキャンセルされる。
  void startTimer() {
    _timer?.cancel();
    _timer = Timer(_idleDuration, () {
      if (!mounted() ||
          lowModeService.isInLowMode ||
          isLocationStreamActive()) return;
      lowModeService
          .enterLowMode(
            getController(),
            getMapStyleMode(),
            onMapStyleChanged,
          )
          .then((_) {
        if (mounted()) _isInIdleLowMode = true;
      });
    });
  }

  /// ユーザーが画面に触れたときに呼ぶ。タイマーをリセットし、無操作で入ったLOWモードなら解除する。
  /// 解除する場合は [leaveLowMode] 完了後に [Future] が resolve する（await 可能）。
  Future<void> onUserInteraction() async {
    startTimer();
    if (!_isInIdleLowMode) return;
    await lowModeService.leaveLowMode(
      getController(),
      onMapStyleChanged,
      saveMapStyleMode,
    );
    if (mounted()) _isInIdleLowMode = false;
  }

  /// タイマーをキャンセルする。dispose 時に呼ぶ。
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// 位置ストリームとプログレスバー（取得中アニメーション）を管理する。
/// ストリーム開始・停止とタイマーを担当し、位置更新は [onPosition] で呼び出し側に渡す。
class LocationTrackingService {
  StreamSubscription<Position>? _subscription;
  Timer? _timer;
  ValueNotifier<double>? _progressBarValue;
  Position? _lastPosition;

  static const _progressBarUpdateInterval = Duration(milliseconds: 100);
  static const _progressBarCycleDuration = Duration(milliseconds: 1800);
  /// LOWモード時の1周期（ゆっくり移動）
  static const _progressBarCycleDurationLowMode = Duration(milliseconds: 3600);

  /// ストリームが動作中かどうか
  bool get isActive => _subscription != null;

  /// プログレスバー用の値（0.0〜1.0 をループ）。停止中は null。
  ValueNotifier<double>? get progressBarValue => _progressBarValue;

  /// 位置ストリームを開始する。
  /// [accuracy] で精度（medium / low）を指定。省略時は medium。
  /// [isLowMode] を渡すと、true のときプログレスバーアニメーションがゆっくりになる。
  void start({
    required void Function(Position position, Position? previous) onPosition,
    required void Function() onError,
    required bool Function() isActive,
    LocationAccuracy accuracy = LocationAccuracy.medium,
    bool Function()? isLowMode,
  }) {
    _lastPosition = null;
    _progressBarValue = ValueNotifier(0.0);

    _timer = Timer.periodic(_progressBarUpdateInterval, (_) {
      if (!isActive() || _subscription == null) return;
      final cycleMs = (isLowMode != null && isLowMode())
          ? _progressBarCycleDurationLowMode.inMilliseconds
          : _progressBarCycleDuration.inMilliseconds;
      final step =
          _progressBarUpdateInterval.inMilliseconds / cycleMs;
      double v = _progressBarValue!.value + step;
      if (v >= 1.0) v = 0.0;
      _progressBarValue!.value = v;
    });

    final stream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: accuracy),
    );

    _subscription = stream.listen(
      (Position position) {
        final previous = _lastPosition;
        _lastPosition = position;
        onPosition(position, previous);
      },
      onError: (_) {
        _stop();
        onError();
      },
    );
  }

  /// ストリームとタイマーを停止する。
  void stop() {
    _stop();
  }

  void _stop() {
    _subscription?.cancel();
    _subscription = null;
    _lastPosition = null;
    _timer?.cancel();
    _timer = null;
    _progressBarValue = null;
  }
}

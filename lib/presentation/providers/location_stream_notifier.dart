import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../domain/services/location_tracking_service.dart';

@immutable
class LocationStreamState {
  const LocationStreamState({
    this.isActive = false,
    this.accuracy = LocationAccuracy.medium,
    this.isInLowMode = false,
    this.progressBarValue,
    this.hasStartedThisSession = false,
  });

  final bool isActive;
  final LocationAccuracy accuracy;
  final bool isInLowMode;

  /// プログレスバー用 ValueNotifier。停止中は null
  final ValueNotifier<double>? progressBarValue;

  /// このセッションで一度でも位置ストリームを開始したか（初回ONでズームを15にするため）
  final bool hasStartedThisSession;

  bool get isAccuracyLow => accuracy == LocationAccuracy.low;

  LocationStreamState copyWith({
    bool? isActive,
    LocationAccuracy? accuracy,
    bool? isInLowMode,
    ValueNotifier<double>? progressBarValue,
    bool? hasStartedThisSession,
    bool clearProgressBar = false,
  }) {
    return LocationStreamState(
      isActive: isActive ?? this.isActive,
      accuracy: accuracy ?? this.accuracy,
      isInLowMode: isInLowMode ?? this.isInLowMode,
      progressBarValue:
          clearProgressBar ? null : (progressBarValue ?? this.progressBarValue),
      hasStartedThisSession:
          hasStartedThisSession ?? this.hasStartedThisSession,
    );
  }
}

/// 位置ストリームの状態を管理する Notifier。
/// [LocationTrackingService] を内部に保持し、ストリームの開始・停止・精度切り替えを担う。
/// カメラ移動など UI 操作は [onPosition] コールバックで Widget 側に委譲する。
class LocationStreamNotifier extends Notifier<LocationStreamState> {
  final LocationTrackingService _service = LocationTrackingService();

  @override
  LocationStreamState build() => const LocationStreamState();

  /// ストリームのON/OFFをトグルする。
  /// ONにする場合は [onPosition] コールバックで位置更新を Widget 側に通知する。
  Future<void> toggle({
    required void Function(Position position, Position? previous) onPosition,
  }) async {
    if (_service.isActive) {
      _service.stop();
      await saveLocationStreamActive(false);
      state = state.copyWith(
        isActive: false,
        clearProgressBar: true,
        isInLowMode: false,
        accuracy: LocationAccuracy.medium,
      );
      return;
    }

    _service.start(
      onPosition: onPosition,
      onError: () {
        state = state.copyWith(isActive: _service.isActive);
      },
      isActive: () => _service.isActive,
      accuracy: state.accuracy,
      isLowMode: () => state.isInLowMode,
    );
    await saveLocationStreamActive(true);
    state = state.copyWith(
      isActive: true,
      progressBarValue: _service.progressBarValue,
      hasStartedThisSession: true,
    );
  }

  /// GPS精度を medium⇔low で切り替えてストリームを再起動する。
  /// ストリームがアクティブでない場合は何もしない。
  Future<void> switchGpsLevel({
    required void Function(Position position, Position? previous) onPosition,
  }) async {
    if (!_service.isActive) return;

    final enteringLow = state.accuracy == LocationAccuracy.medium;
    final newAccuracy =
        enteringLow ? LocationAccuracy.low : LocationAccuracy.medium;

    _service.stop();
    state = state.copyWith(
      isActive: false,
      accuracy: newAccuracy,
      isInLowMode: enteringLow,
      clearProgressBar: true,
    );

    _service.start(
      onPosition: onPosition,
      onError: () {
        state = state.copyWith(isActive: _service.isActive);
      },
      isActive: () => _service.isActive,
      accuracy: newAccuracy,
      isLowMode: () => state.isInLowMode,
    );
    state = state.copyWith(
      isActive: true,
      progressBarValue: _service.progressBarValue,
    );
  }

  /// ストリームを停止する（ライフサイクル管理など外部から停止する場合）
  void stop() {
    if (!_service.isActive) return;
    _service.stop();
    state = state.copyWith(
      isActive: false,
      clearProgressBar: true,
    );
  }

  /// バックグラウンドから復帰時: 保存済み設定でストリームを復元する
  Future<void> restoreFromSaved({
    required void Function(Position position, Position? previous) onPosition,
  }) async {
    final wasActive = await loadLocationStreamActive();
    if (wasActive) {
      await toggle(onPosition: onPosition);
    }
  }
}

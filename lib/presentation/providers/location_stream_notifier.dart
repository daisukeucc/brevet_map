import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../domain/services/location_tracking_service.dart';

@immutable
class LocationStreamState {
  const LocationStreamState({
    this.isActive = false,
    this.progressBarValue,
    this.hasStartedThisSession = false,
  });

  final bool isActive;

  /// プログレスバー用 ValueNotifier。停止中は null
  final ValueNotifier<double>? progressBarValue;

  /// このセッションで一度でも位置ストリームを開始したか（初回ONでズームを15にするため）
  final bool hasStartedThisSession;

  LocationStreamState copyWith({
    bool? isActive,
    ValueNotifier<double>? progressBarValue,
    bool? hasStartedThisSession,
    bool clearProgressBar = false,
  }) {
    return LocationStreamState(
      isActive: isActive ?? this.isActive,
      progressBarValue:
          clearProgressBar ? null : (progressBarValue ?? this.progressBarValue),
      hasStartedThisSession:
          hasStartedThisSession ?? this.hasStartedThisSession,
    );
  }
}

/// 位置ストリームの状態を管理する Notifier。
/// [LocationTrackingService] を内部に保持し、ストリームの開始・停止を担う。
/// カメラ移動など UI 操作は [onPosition] コールバックで Widget 側に委譲する。
class LocationStreamNotifier extends Notifier<LocationStreamState> {
  final LocationTrackingService _service = LocationTrackingService();

  /// ユーザーがこのセッションで ON にした（バックグラウンドで停止しても復帰時に再開する）。
  /// プロセス終了（アプリ Kill）でリセットされる。永続化はしない。
  bool _sessionWantsLocationStream = false;

  @override
  LocationStreamState build() => const LocationStreamState();

  void _startService({
    required void Function(Position position, Position? previous) onPosition,
  }) {
    _service.start(
      onPosition: onPosition,
      onError: () {
        state = state.copyWith(isActive: _service.isActive);
      },
      isActive: () => _service.isActive,
    );
  }

  /// ストリームのON/OFFをトグルする。
  /// ONにする場合は [onPosition] コールバックで位置更新を Widget 側に通知する。
  Future<void> toggle({
    required void Function(Position position, Position? previous) onPosition,
  }) async {
    if (_service.isActive) {
      _service.stop();
      _sessionWantsLocationStream = false;
      await saveLocationStreamActive(false);
      state = state.copyWith(
        isActive: false,
        clearProgressBar: true,
      );
      return;
    }

    _sessionWantsLocationStream = true;
    _startService(onPosition: onPosition);
    state = state.copyWith(
      isActive: true,
      progressBarValue: _service.progressBarValue,
      hasStartedThisSession: true,
    );
  }

  /// ストリームを停止する（ライフサイクル管理など外部から停止する場合）
  /// [_sessionWantsLocationStream] は維持する（フォアグラウンド復帰時に再開するため）。
  void stop() {
    if (!_service.isActive) return;
    _service.stop();
    state = state.copyWith(
      isActive: false,
      clearProgressBar: true,
    );
  }

  /// フォアグラウンド復帰時: セッション中に ON だった場合のみストリームを再開する。
  /// 再開に成功したら true。
  Future<bool> resumeForegroundIfNeeded({
    required void Function(Position position, Position? previous) onPosition,
    required Future<bool> Function() ensurePermission,
  }) async {
    if (!_sessionWantsLocationStream || _service.isActive) return false;
    if (!await ensurePermission()) return false;
    _startService(onPosition: onPosition);
    state = state.copyWith(
      isActive: true,
      progressBarValue: _service.progressBarValue,
      hasStartedThisSession: true,
    );
    return true;
  }
}

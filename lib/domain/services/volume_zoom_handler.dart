import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_map/flutter_map.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:flutter_android_volume_keydown/flutter_android_volume_keydown.dart';

/// ボリュームボタンで地図ズームするリスナー。[getController] で現在の MapController を渡す。
class VolumeZoomHandler {
  VolumeZoomHandler({required this.getController});

  final MapController? Function() getController;

  static const _zoomAmountUp = 1.0;
  static const _zoomAmountDown = 1.0;
  static const _debounce = Duration(milliseconds: 400);

  /// iOS: 常にこの音量に復元する。差分がほぼ0なら復元コールバックとみなしスキップ。
  static const _anchorVolume = 0.5;
  /// iOSの音量ステップは 1/16≒0.0625。復元後のわずかなズレを吸収するため 0.03 に設定。
  static const _threshold = 0.03;

  StreamSubscription<double>? _volumeSubscription;
  StreamSubscription<HardwareButton>? _volumeKeySubscription;
  DateTime? _lastKeyTime;
  HardwareButton? _lastKeyButton;
  DateTime? _lastChangeTime;
  bool _iosInitialized = false;

  void start() {
    if (Platform.isAndroid) {
      _volumeKeySubscription =
          FlutterAndroidVolumeKeydown.stream.listen((event) {
        final controller = getController();
        if (controller == null) return;
        final now = DateTime.now();
        if (_lastKeyTime != null &&
            _lastKeyButton == event &&
            now.difference(_lastKeyTime!) < _debounce) {
          return;
        }
        _lastKeyTime = now;
        _lastKeyButton = event;
        final center = controller.camera.center;
        final zoom = controller.camera.zoom;
        if (event == HardwareButton.volume_up) {
          controller.move(center, zoom + _zoomAmountUp);
        } else if (event == HardwareButton.volume_down) {
          controller.move(center, (zoom - _zoomAmountDown).clamp(0.0, 22.0));
        }
      });
      return;
    }

    // iOS: fetchInitialVolume:true で最初のコールバックを初期化に使い、
    // その後 setVolume でアンカーに固定する。Timerを使わないためズレが起きない。
    VolumeController.instance.showSystemUI = false;

    _volumeSubscription = VolumeController.instance.addListener((volume) {
      // 最初のコールバックは現在音量の取得。アンカーにセットして初期化完了。
      if (!_iosInitialized) {
        _iosInitialized = true;
        VolumeController.instance.setVolume(_anchorVolume);
        return;
      }

      final diff = volume - _anchorVolume;
      // アンカーとの差が閾値以下 = 復元コールバックなので無視
      if (diff.abs() < _threshold) return;

      // アンカーに戻す（このコールバックは diff≈0 で自然にスキップされる）
      VolumeController.instance.setVolume(_anchorVolume);

      // デバウンス
      final now = DateTime.now();
      if (_lastChangeTime != null &&
          now.difference(_lastChangeTime!) < _debounce) {
        return;
      }
      _lastChangeTime = now;

      final controller = getController();
      if (controller == null) return;
      final center = controller.camera.center;
      final zoom = controller.camera.zoom;
      if (diff > 0) {
        controller.move(center, zoom + _zoomAmountUp);
      } else {
        controller.move(center, (zoom - _zoomAmountDown).clamp(0.0, 22.0));
      }
    }, fetchInitialVolume: true);
  }

  void dispose() {
    _volumeSubscription?.cancel();
    _volumeSubscription = null;
    _volumeKeySubscription?.cancel();
    _volumeKeySubscription = null;
  }
}

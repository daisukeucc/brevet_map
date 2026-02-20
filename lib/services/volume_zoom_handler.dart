import 'dart:async';
import 'dart:io' show Platform;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:flutter_android_volume_keydown/flutter_android_volume_keydown.dart';

/// ボリュームボタンで地図ズームするリスナー。[getController] で現在の MapController を渡す。
class VolumeZoomHandler {
  VolumeZoomHandler({required this.getController});

  final GoogleMapController? Function() getController;

  static const _zoomAmountUp = 1.2;
  static const _zoomAmountDown = 1.2;
  static const _debounce = Duration(milliseconds: 400);

  StreamSubscription<double>? _volumeSubscription;
  StreamSubscription<HardwareButton>? _volumeKeySubscription;
  double? _previousVolume;
  DateTime? _lastKeyTime;
  HardwareButton? _lastKeyButton;
  DateTime? _lastChangeTime;
  bool? _lastChangeUp;

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
        if (event == HardwareButton.volume_up) {
          controller.animateCamera(CameraUpdate.zoomBy(_zoomAmountUp));
        } else if (event == HardwareButton.volume_down) {
          controller.animateCamera(CameraUpdate.zoomBy(-_zoomAmountDown));
        }
      });
      return;
    }
    VolumeController.instance.showSystemUI = false;
    _volumeSubscription = VolumeController.instance.addListener((volume) {
      if (_previousVolume == null) {
        _previousVolume = volume;
        return;
      }
      final now = DateTime.now();
      final isUp = volume > _previousVolume!;
      final isDown = volume < _previousVolume!;
      final controller = getController();
      if (isUp && controller != null) {
        if (_lastChangeTime != null &&
            _lastChangeUp == true &&
            now.difference(_lastChangeTime!) < _debounce) {
          VolumeController.instance.setVolume(_previousVolume!);
          return;
        }
        _lastChangeTime = now;
        _lastChangeUp = true;
        controller.animateCamera(CameraUpdate.zoomBy(_zoomAmountUp));
        VolumeController.instance.setVolume(_previousVolume!);
        return;
      }
      if (isDown && controller != null) {
        if (_lastChangeTime != null &&
            _lastChangeUp == false &&
            now.difference(_lastChangeTime!) < _debounce) {
          VolumeController.instance.setVolume(_previousVolume!);
          return;
        }
        _lastChangeTime = now;
        _lastChangeUp = false;
        controller.animateCamera(CameraUpdate.zoomBy(-_zoomAmountDown));
        VolumeController.instance.setVolume(_previousVolume!);
        return;
      }
      _previousVolume = volume;
    }, fetchInitialVolume: true);
  }

  void dispose() {
    _volumeSubscription?.cancel();
    _volumeSubscription = null;
    _volumeKeySubscription?.cancel();
    _volumeKeySubscription = null;
  }
}

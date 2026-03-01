import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// [MapController] を保持し、カメラ操作APIを集約する。
/// build() で MapController を生成するため、常に非 null。
class CameraControllerNotifier extends Notifier<MapController> {
  @override
  MapController build() {
    final controller = MapController();
    ref.onDispose(controller.dispose);
    return controller;
  }

  /// 指定座標へカメラを移動する
  /// FlutterMap が未レンダリングの場合は何もしない。
  Future<void> animateTo(
    LatLng target, {
    double? zoom,
    double bearing = 0.0,
  }) async {
    try {
      state.moveAndRotate(target, zoom ?? 15.0, bearing);
    } catch (_) {}
  }

  /// ルート全体が収まるようにカメラを移動する
  /// FlutterMap が未レンダリングの場合は何もしない。
  Future<void> animateToBounds(LatLngBounds bounds, {double padding = 30}) async {
    try {
      state.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: EdgeInsets.all(padding),
        ),
      );
    } catch (_) {}
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// [MapController] への参照を保持し、カメラ操作APIを集約する。
/// onMapCreated コールバックで [setController] を呼び出すことで初期化される。
class CameraControllerNotifier extends Notifier<MapController?> {
  @override
  MapController? build() => null;

  /// onMapCreated で受け取った controller を登録する
  void setController(MapController controller) => state = controller;

  /// controller をクリアする（オフライン→オンライン遷移時に破棄済み controller の使用を防ぐ）
  void clearController() => state = null;

  /// 指定座標へカメラをアニメーション移動する
  Future<void> animateTo(
    LatLng target, {
    double? zoom,
    double bearing = 0.0,
    double tilt = 0.0,
  }) async {
    final ctrl = state;
    if (ctrl == null) return;
    ctrl.move(target, zoom ?? 15.0);
    if (bearing != 0.0) {
      ctrl.rotate(-bearing);
    }
  }

  /// 地図上下のボタン（60x60）＋余白に合わせたパディング。
  /// ルート拡大表示でスタート・ゴールがボタンに隠れないようにする。
  static const _fitPadding = EdgeInsets.only(
    top: 100,
    bottom: 100,
    left: 30,
    right: 30,
  );

  /// ルート全体が収まるようにカメラをアニメーション移動する
  Future<void> animateToBounds(LatLngBounds bounds) async {
    final ctrl = state;
    if (ctrl == null) return;
    try {
      ctrl.rotate(0);
      ctrl.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: _fitPadding,
        ),
      );
    } catch (_) {
      // FlutterMap が未レンダー時に controller 使用で例外が出る場合がある（オフライン復帰時など）
    }
  }

  /// 位置を変えずに地図の向きだけ変更する（停止時コンパス更新用）
  void rotateTo(double bearing) {
    state?.rotate(-bearing);
  }

  /// 現在のズームレベルを取得する。controller未設定の場合は null
  Future<double?> getZoomLevel() async {
    return state?.camera.zoom;
  }
}

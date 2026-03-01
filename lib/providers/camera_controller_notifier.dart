import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// [GoogleMapController] への参照を保持し、カメラ操作APIを集約する。
/// onMapCreated コールバックで [setController] を呼び出すことで初期化される。
class CameraControllerNotifier extends Notifier<GoogleMapController?> {
  @override
  GoogleMapController? build() => null;

  /// onMapCreated で受け取った controller を登録する
  void setController(GoogleMapController controller) => state = controller;

  /// 指定座標へカメラをアニメーション移動する
  Future<void> animateTo(
    LatLng target, {
    double? zoom,
    double bearing = 0.0,
    double tilt = 0.0,
  }) async {
    await state?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          bearing: bearing,
          zoom: zoom ?? 15.0,
          tilt: tilt,
        ),
      ),
    );
  }

  /// ルート全体が収まるようにカメラをアニメーション移動する
  Future<void> animateToBounds(LatLngBounds bounds, {double padding = 30}) async {
    await state?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  /// 現在のズームレベルを取得する。controller未設定の場合は null
  Future<double?> getZoomLevel() async {
    return state?.getZoomLevel();
  }

  /// 地図スタイルを設定する
  Future<void> setMapStyle(String? style) async {
    // ignore: deprecated_member_use
    await state?.setMapStyle(style);
  }
}

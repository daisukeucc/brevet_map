import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../config/api_config.dart';
import '../../data/parsers/gpx_parser.dart';
import '../../data/repositories/directions_repository.dart';
import '../../data/repositories/first_launch_repository.dart';
import '../../domain/models/user_poi.dart';
import '../../utils/map_utils.dart';

/// 保存済みルートとPOIをまとめて読み込む。初回起動判定は呼び出し側で行う。
Future<({List<LatLng>? points, List<GpxPoi> pois})>
    loadSavedRouteWithPois() async {
  final points = await loadSavedRoute();
  final poisJson = await loadGpxPois();
  List<GpxPoi> pois = [];
  if (poisJson != null && poisJson.isNotEmpty) {
    try {
      final list = jsonDecode(poisJson) as List<dynamic>;
      pois =
          list.map((e) => GpxPoi.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
  }
  return (points: points, pois: pois);
}

/// 保存済みルートのポリラインをデコードして返す。未保存なら null。
Future<List<LatLng>?> loadSavedRoute() async {
  final encoded = await loadRouteEncoded();
  if (encoded == null || encoded.isEmpty) return null;
  try {
    return decodePolyline(encoded);
  } catch (_) {
    return null;
  }
}

/// 初回起動時のサンプル POI を生成して返す。
/// ルート上の 10/20/40/60/80km 地点に配置する。
List<UserPoi> buildSamplePois(List<LatLng> routePoints) {
  const specs = [
    (km: 10.0, type: 1, title: 'Info'),
    (km: 20.0, type: 0, title: 'CP1'),
    (km: 40.0, type: 0, title: 'CP2'),
    (km: 60.0, type: 1, title: 'Info'),
    (km: 80.0, type: 0, title: 'CP3'),
  ];
  final pois = <UserPoi>[];
  for (final spec in specs) {
    final coord = coordAtKm(routePoints, spec.km);
    if (coord == null) continue;
    pois.add(UserPoi(
      type: spec.type,
      km: spec.km,
      title: spec.title,
      body: 'Details',
      lat: coord.latitude,
      lng: coord.longitude,
    ));
  }
  return pois;
}

/// 初回なら Directions API でルート取得・保存、2回目以降は保存済みを使用。
Future<List<LatLng>?> fetchOrLoadRoute(
  Position position, {
  List<LatLng>? savedRoutePoints,
}) async {
  final isFirst = await isFirstLaunch();

  if (isFirst) {
    final current = LatLng(position.latitude, position.longitude);
    final waypoints = computeWaypointsFor100kmLoop(
      position.latitude,
      position.longitude,
    );
    final result = await fetchDirections(
      origin: current,
      destination: current,
      apiKey: googleMapsApiKey,
      waypoints: waypoints,
    );
    if (result == null || result.points.isEmpty) return null;
    // API 成功時のみ初回フラグを立てる（失敗時は次回起動でも再取得を試みる）
    await saveRouteEncoded(result.encoded);
    await clearTrackElevations();
    await markInitialRouteShown();
    return result.points;
  }

  if (savedRoutePoints != null && savedRoutePoints.isNotEmpty) {
    return savedRoutePoints;
  }
  return await loadSavedRoute();
}

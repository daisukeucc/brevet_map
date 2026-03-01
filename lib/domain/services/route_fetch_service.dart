import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../data/parsers/gpx_parser.dart';
import '../../data/repositories/directions_repository.dart';
import '../../data/repositories/first_launch_repository.dart';
import '../../data/repositories/route_repository.dart';

/// 旧形式（SharedPreferences）から新形式（ファイル）への一回限りの移行。
/// active_route_id が未設定かつ saved_route_polyline が存在する場合のみ実行する。
/// 移行後は旧キーを削除して routeId を返す。
Future<String?> _migrateFromSharedPreferences() async {
  final activeId = await loadActiveRouteId();
  if (activeId != null) return activeId;

  final prefs = await SharedPreferences.getInstance();
  final encoded = prefs.getString('saved_route_polyline');
  if (encoded == null || encoded.isEmpty) return null;

  final poisJson = prefs.getString('gpx_pois');
  List<GpxPoi> pois = [];
  if (poisJson != null && poisJson.isNotEmpty) {
    try {
      final list = jsonDecode(poisJson) as List<dynamic>;
      pois =
          list.map((e) => GpxPoi.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
  }

  final routeId = generateRouteId();
  await saveRouteToFile(
    routeId: routeId,
    name: 'migrated',
    encodedPolyline: encoded,
    pois: pois,
  );
  await saveActiveRouteId(routeId);

  // 旧 SharedPreferences キーを削除
  await prefs.remove('saved_route_polyline');
  await prefs.remove('gpx_pois');

  return routeId;
}

/// アクティブルートのデータ（ポリライン + POI）を読み込む。
/// 旧形式の場合は自動的に移行してから読む。
Future<({List<LatLng>? points, List<GpxPoi> pois, String? routeId})>
    loadSavedRouteWithPois() async {
  final routeId = await _migrateFromSharedPreferences();
  if (routeId == null) {
    return (points: null, pois: const <GpxPoi>[], routeId: null);
  }

  final data = await loadRouteFromFile(routeId);
  if (data == null) {
    return (points: null, pois: const <GpxPoi>[], routeId: null);
  }

  List<LatLng>? points;
  if (data.polyline != null && data.polyline!.isNotEmpty) {
    try {
      points = decodePolyline(data.polyline!);
    } catch (_) {}
  }

  return (points: points, pois: data.pois, routeId: routeId);
}

/// 初回なら Directions API でルート取得・保存、2回目以降は保存済みファイルを使用。
/// 戻り値: (points, routeId) のレコード。取得できない場合は null。
Future<({List<LatLng> points, String routeId})?> fetchOrLoadRoute(
  Position position, {
  List<LatLng>? savedRoutePoints,
  String? activeRouteId,
}) async {
  final isFirst = await isFirstLaunch();

  if (isFirst) {
    final current = LatLng(position.latitude, position.longitude);
    final waypoints =
        computeWaypointsFor100kmLoop(position.latitude, position.longitude);
    final result = await fetchDirections(
      origin: current,
      destination: current,
      apiKey: googleMapsApiKey,
      waypoints: waypoints,
    );
    if (result == null || result.points.isEmpty) return null;

    final routeId = generateRouteId();
    await saveRouteToFile(
      routeId: routeId,
      name: 'initial',
      encodedPolyline: result.encoded,
      pois: const [],
    );
    await saveActiveRouteId(routeId);
    await markInitialRouteShown();
    return (points: result.points, routeId: routeId);
  }

  // メモリにロード済みならそのまま使用
  if (savedRoutePoints != null &&
      savedRoutePoints.isNotEmpty &&
      activeRouteId != null) {
    return (points: savedRoutePoints, routeId: activeRouteId);
  }

  // ファイルから読み込む（移行も含む）
  final loaded = await loadSavedRouteWithPois();
  if (loaded.points == null || loaded.points!.isEmpty || loaded.routeId == null) {
    return null;
  }
  return (points: loaded.points!, routeId: loaded.routeId!);
}

import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/api_config.dart';
import '../parsers/gpx_parser.dart';
import '../repositories/directions_repository.dart';
import '../repositories/first_launch_repository.dart';

/// 保存済みルートとPOIをまとめて読み込む。初回起動判定は呼び出し側で行う。
Future<({List<LatLng>? points, List<GpxPoi> pois})> loadSavedRouteWithPois() async {
  final points = await loadSavedRoute();
  final poisJson = await loadGpxPois();
  List<GpxPoi> pois = [];
  if (poisJson != null && poisJson.isNotEmpty) {
    try {
      final list = jsonDecode(poisJson) as List<dynamic>;
      pois = list
          .map((e) => GpxPoi.fromJson(e as Map<String, dynamic>))
          .toList();
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
    await saveRouteEncoded(result.encoded);
    await markInitialRouteShown();
    return result.points;
  }

  if (savedRoutePoints != null && savedRoutePoints.isNotEmpty) {
    return savedRoutePoints;
  }
  return await loadSavedRoute();
}

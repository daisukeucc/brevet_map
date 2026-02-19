import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../parsers/gpx_parser.dart';
import '../repositories/directions_repository.dart';
import '../repositories/first_launch_repository.dart';

/// GPX をパースして永続化した結果。UI 側で setState やカメラに使う。
class GpxImportResult {
  const GpxImportResult({
    required this.trackPoints,
    required this.waypoints,
  });

  final List<LatLng> trackPoints;
  final List<GpxPoi> waypoints;

  bool get isEmpty => trackPoints.isEmpty && waypoints.isEmpty;
}

/// GPX 文字列をパースし、ルート・POI を保存する。
/// - パース失敗時は null
/// - トラックもウェイポイントも無い場合は [GpxImportResult] を返す（isEmpty == true）。保存は行わない
/// - それ以外は clear → save して [GpxImportResult] を返す
Future<GpxImportResult?> parseAndSaveGpx(String gpxContent) async {
  final result = parseGpx(gpxContent);
  if (result == null) return null;

  if (result.trackPoints.isEmpty && result.waypoints.isEmpty) {
    return GpxImportResult(trackPoints: [], waypoints: []);
  }

  await clearSavedRoute();

  if (result.trackPoints.isNotEmpty) {
    final encoded = encodePolyline(result.trackPoints);
    await saveRouteEncoded(encoded);
    await markInitialRouteShown();
  }

  if (result.waypoints.isNotEmpty) {
    final poisJson = jsonEncode(
      result.waypoints.map((p) => p.toJson()).toList(),
    );
    await saveGpxPois(poisJson);
  }

  return GpxImportResult(
    trackPoints: result.trackPoints,
    waypoints: result.waypoints,
  );
}

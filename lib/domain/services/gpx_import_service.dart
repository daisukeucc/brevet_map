import 'package:latlong2/latlong.dart';

import '../../data/parsers/gpx_parser.dart';
import '../../data/repositories/directions_repository.dart';
import '../../data/repositories/first_launch_repository.dart';
import '../../data/repositories/route_repository.dart';

/// GPX をパースして永続化した結果。UI 側で setState やカメラに使う。
class GpxImportResult {
  const GpxImportResult({
    required this.trackPoints,
    required this.waypoints,
    this.routeId,
  });

  final List<LatLng> trackPoints;
  final List<GpxPoi> waypoints;

  /// 保存されたルートID（空・parseError 時は null）
  final String? routeId;

  bool get isEmpty => trackPoints.isEmpty && waypoints.isEmpty;
}

/// GPX 文字列をパースし、ルートIDフォルダ構造で保存する。
/// - パース失敗時は null
/// - トラックもウェイポイントも無い場合は isEmpty == true の結果を返す（保存なし）
/// - それ以外は routes/{routeId}/ に保存してアクティブルートIDを更新する
Future<GpxImportResult?> parseAndSaveGpx(String gpxContent) async {
  final result = parseGpx(gpxContent);
  if (result == null) return null;

  if (result.trackPoints.isEmpty && result.waypoints.isEmpty) {
    return const GpxImportResult(trackPoints: [], waypoints: []);
  }

  final routeId = generateRouteId();

  if (result.trackPoints.isNotEmpty) {
    final encoded = encodePolyline(result.trackPoints);
    await saveRouteToFile(
      routeId: routeId,
      name: 'imported',
      encodedPolyline: encoded,
      pois: result.waypoints,
    );
  } else {
    // ウェイポイントのみの場合もフォルダを作成して保存する
    await saveRouteToFile(
      routeId: routeId,
      name: 'imported',
      encodedPolyline: '',
      pois: result.waypoints,
    );
  }

  await saveActiveRouteId(routeId);
  await markInitialRouteShown();

  return GpxImportResult(
    trackPoints: result.trackPoints,
    waypoints: result.waypoints,
    routeId: routeId,
  );
}

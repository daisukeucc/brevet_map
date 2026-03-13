import 'package:latlong2/latlong.dart';

import '../../data/parsers/gpx_parser.dart';
import '../../data/repositories/directions_repository.dart';
import '../../data/repositories/first_launch_repository.dart';
import '../../domain/models/user_poi.dart';
import '../../data/repositories/user_poi_repository.dart';
import '../../utils/string_utils.dart';

/// GPX をパースして永続化した結果。UI 側で setState やカメラに使う。
class GpxImportResult {
  const GpxImportResult({
    required this.trackPoints,
    required this.userPois,
  });

  final List<LatLng> trackPoints;

  /// wpt を UserPoi に変換したリスト（編集可能）
  final List<UserPoi> userPois;

  bool get isEmpty => trackPoints.isEmpty && userPois.isEmpty;
}

/// <name> の先頭が「Nkm：」「N.Nkm：」の場合、(km, title) を返す。
/// 該当しない場合は (null, name) を返す。
({double? km, String title}) _parseNameAndKm(String name) {
  final match = RegExp(r'^\s*(\d+(?:\.\d+)?)\s*km\s*[：:]\s*(.*)$', dotAll: true)
      .firstMatch(name);
  if (match == null) return (km: null, title: name);
  final km = double.tryParse(match.group(1) ?? '');
  final title = (match.group(2) ?? '').trim();
  return (km: km, title: title);
}

/// GpxPoi を UserPoi に変換する。
/// - type: <type>/<cmt> が control/checkpoint なら 0、 else 1
/// - km: <name> 先頭に「Nkm：」があれば N、なければ null
/// - title: <name> から距離プレフィックスを除去した実質的なタイトル
/// - body: <desc>
UserPoi _gpxPoiToUserPoi(GpxPoi poi) {
  final rawName = poi.name ?? '';
  final parsed = _parseNameAndKm(rawName);
  return UserPoi(
    type: poi.isControl ? 0 : 1,
    km: parsed.km,
    title: parsed.title,
    body: poi.description ?? '',
    lat: poi.lat,
    lng: poi.lng,
  );
}

/// GPX 文字列をパースし、ルート・POI を保存する。
/// - パース失敗時は null
/// - トラックもウェイポイントも無い場合は [GpxImportResult] を返す（isEmpty == true）。保存は行わない
/// - wpt は UserPoi に変換して保存し、編集可能にする
/// - [importFilename] ファイルピッカーから取得したファイル名（.gpx 除く）。metadata が空のときのフォールバック
Future<GpxImportResult?> parseAndSaveGpx(
  String gpxContent, {
  String? importFilename,
}) async {
  final result = parseGpx(gpxContent);
  if (result == null) return null;

  if (result.trackPoints.isEmpty && result.waypoints.isEmpty) {
    return const GpxImportResult(trackPoints: [], userPois: []);
  }

  await clearSavedRoute();

  if (result.trackPoints.isNotEmpty) {
    final encoded = encodePolyline(result.trackPoints);
    await saveRouteEncoded(encoded);
    await markInitialRouteShown();
  }

  final nameToSave = (result.metadataName != null && result.metadataName!.isNotEmpty)
      ? result.metadataName!
      : (importFilename?.trim().isNotEmpty == true ? importFilename!.trim() : null);
  if (nameToSave != null) {
    await saveGpxMetadataName(toHalfwidthAscii(nameToSave));
  }

  final userPois = result.waypoints.map(_gpxPoiToUserPoi).toList();
  await saveUserPois(userPois); // トラックのみのGPXでも必ず上書き（過去のPOIをクリアするため）

  return GpxImportResult(
    trackPoints: result.trackPoints,
    userPois: userPois,
  );
}

import 'dart:convert';

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
    this.trackElevations,
    this.gpxDotWaypoints = const [],
  });

  final List<LatLng> trackPoints;

  /// `<type>Dot</type>` 以外の wpt を UserPoi に変換したリスト（マーカー・編集対象）
  final List<UserPoi> userPois;

  /// `<type>Dot</type>` の wpt。表示・編集せずエクスポートで元どおり出す
  final List<GpxPoi> gpxDotWaypoints;

  /// 各 trkpt の `<ele>`。[trackPoints] と同じ長さ。
  final List<double?>? trackElevations;

  bool get isEmpty =>
      trackPoints.isEmpty && userPois.isEmpty && gpxDotWaypoints.isEmpty;
}

/// <name> の先頭が「Nkm：」「N.Nkm：」の場合、(km, title) を返す。
({double? km, String title}) _parseNameAndKm(String name) {
  final match = RegExp(r'^\s*(\d+(?:\.\d+)?)\s*km\s*[：:]\s*(.*)$', dotAll: true)
      .firstMatch(name);
  if (match == null) return (km: null, title: name);
  final km = double.tryParse(match.group(1) ?? '');
  final title = (match.group(2) ?? '').trim();
  return (km: km, title: title);
}

/// GpxPoi を UserPoi に変換する（Dot 以外のみ）。
/// チェックポイント: `<type>checkpoint</type>` → [UserPoi.type] 0
UserPoi _gpxPoiToUserPoi(GpxPoi poi) {
  final rawName = poi.name ?? '';
  final parsed = _parseNameAndKm(rawName);
  return UserPoi(
    type: poi.isCheckpoint ? 0 : 1,
    km: parsed.km,
    title: parsed.title,
    body: poi.description ?? '',
    lat: poi.lat,
    lng: poi.lng,
    gpxCmt: poi.cmt,
    gpxType: poi.type,
  );
}

/// GPX 文字列をパースし、ルート・POI を保存する。
Future<GpxImportResult?> parseAndSaveGpx(
  String gpxContent, {
  String? importFilename,
}) async {
  final result = parseGpx(gpxContent);
  if (result == null) return null;

  if (result.trackPoints.isEmpty && result.waypoints.isEmpty) {
    return const GpxImportResult(
      trackPoints: [],
      userPois: [],
      gpxDotWaypoints: [],
    );
  }

  await clearSavedRoute();

  if (result.trackPoints.isNotEmpty) {
    final encoded = encodePolyline(result.trackPoints);
    await saveRouteEncoded(encoded);
    await saveTrackElevations(result.trackElevations);
    await markInitialRouteShown();
  }

  final nameToSave = (result.metadataName != null && result.metadataName!.isNotEmpty)
      ? result.metadataName!
      : (importFilename?.trim().isNotEmpty == true ? importFilename!.trim() : null);
  if (nameToSave != null) {
    await saveGpxMetadataName(toHalfwidthAscii(nameToSave));
  }

  final dotWpts =
      result.waypoints.where((w) => w.isGpxDotType).toList(growable: false);
  final visibleWpts =
      result.waypoints.where((w) => !w.isGpxDotType).toList(growable: false);

  await saveGpxDotWaypointsJson(
    jsonEncode(dotWpts.map((e) => e.toJson()).toList()),
  );

  final userPois = visibleWpts.map(_gpxPoiToUserPoi).toList();
  await saveUserPois(userPois);

  return GpxImportResult(
    trackPoints: result.trackPoints,
    userPois: userPois,
    gpxDotWaypoints: dotWpts,
    trackElevations:
        result.trackPoints.isNotEmpty ? result.trackElevations : null,
  );
}

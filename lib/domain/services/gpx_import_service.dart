import 'dart:convert';

import 'package:latlong2/latlong.dart';

import '../../data/parsers/gpx_parser.dart';
import '../../data/repositories/directions_repository.dart';
import '../../data/repositories/first_launch_repository.dart';
import '../../domain/models/bm_extension.dart';
import '../../domain/models/brevet_distances.dart';
import '../../domain/models/user_poi.dart';
import '../../data/repositories/user_poi_repository.dart';
import '../../utils/map_utils.dart';
import '../../utils/string_utils.dart';

/// GPX をパースして永続化した結果。UI 側で setState やカメラに使う。
class GpxImportResult {
  const GpxImportResult({
    required this.trackPoints,
    required this.userPois,
    this.trackElevations,
    this.gpxDotWaypoints = const [],
    this.brevetMeta,
  });

  final List<LatLng> trackPoints;

  /// `<type>Dot</type>` 以外の wpt を UserPoi に変換したリスト（マーカー・編集対象）
  final List<UserPoi> userPois;

  /// `<type>Dot</type>` の wpt。表示・編集せずエクスポートで元どおり出す
  final List<GpxPoi> gpxDotWaypoints;

  /// 各 trkpt の `<ele>`。[trackPoints] と同じ長さ。
  final List<double?>? trackElevations;

  /// インポートされた、または自動生成されたブルベメタデータ
  final BmBrevetMeta? brevetMeta;

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
/// 既存の `<bm:poi>` があればそれを使い、なければ [brevetMeta] から既定値を生成する。
UserPoi _gpxPoiToUserPoi(
  GpxPoi poi, {
  List<LatLng> trackPoints = const [],
  required BmBrevetMeta brevetMeta,
}) {
  final rawName = poi.name ?? '';
  final parsed = _parseNameAndKm(rawName);
  double? km = parsed.km;
  if (km == null && trackPoints.isNotEmpty) {
    final meters =
        distanceFromStartToPointAlongTrack(trackPoints, poi.position);
    km = meters / 1000;
  }

  final bmExt = poi.bmPoiExt ??
      _defaultBmPoiExtension(
        poiType: poi.type?.trim().toLowerCase() ??
            (poi.isCheckpoint ? 'checkpoint' : 'generic'),
        distanceKm: km ?? 0,
        brevetMeta: brevetMeta,
      );

  return UserPoi(
    type: poi.isCheckpoint ? 0 : 1,
    km: km,
    title: parsed.title,
    body: poi.description ?? '',
    lat: poi.lat,
    lng: poi.lng,
    gpxCmt: poi.cmt,
    gpxType: poi.type,
    bmExt: bmExt,
  );
}

/// POI 種別に応じた既定の [BmPoiExtension] を生成する。
BmPoiExtension _defaultBmPoiExtension({
  required String poiType,
  required double distanceKm,
  required BmBrevetMeta brevetMeta,
}) {
  final BmSchedule schedule;
  switch (poiType) {
    case 'start':
      schedule = BmSchedule(
        departure: brevetMeta.startTime,
      );
    case 'finish':
      final limitDuration =
          Duration(minutes: (brevetMeta.timeLimitHours * 60).round());
      schedule = BmSchedule(
        arrival: brevetMeta.startTime.add(limitDuration),
      );
    default:
      schedule = const BmSchedule();
  }

  return BmPoiExtension(
    type: poiType,
    schedule: schedule,
    distanceKm: distanceKm,
  );
}

/// スタート POI を新規作成する（GPX にスタート wpt がない場合）。
UserPoi _createStartPoi(LatLng position, BmBrevetMeta brevetMeta) {
  return UserPoi(
    type: 1,
    km: 0,
    title: 'Start',
    body: '',
    lat: position.latitude,
    lng: position.longitude,
    bmExt: _defaultBmPoiExtension(
      poiType: 'start',
      distanceKm: 0,
      brevetMeta: brevetMeta,
    ),
  );
}

/// ゴール POI を新規作成する（GPX にゴール wpt がない場合）。
UserPoi _createFinishPoi(
  LatLng position,
  double totalDistanceKm,
  BmBrevetMeta brevetMeta,
) {
  return UserPoi(
    type: 1,
    km: totalDistanceKm,
    title: 'Goal',
    body: '',
    lat: position.latitude,
    lng: position.longitude,
    bmExt: _defaultBmPoiExtension(
      poiType: 'finish',
      distanceKm: totalDistanceKm,
      brevetMeta: brevetMeta,
    ),
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

  // ルート距離計算
  final trackPoints = result.trackPoints;
  final totalDistanceKm = trackPoints.isNotEmpty
      ? distanceAlongTrackFromStart(trackPoints, trackPoints.length - 1) / 1000
      : 0.0;

  // ブルベメタデータ決定
  final BmBrevetMeta brevetMeta;
  if (result.brevetMeta != null) {
    brevetMeta = result.brevetMeta!;
  } else {
    final matched = matchBrevetDistance(totalDistanceKm);
    final now = DateTime.now().toUtc();
    final startTime = DateTime.utc(now.year, now.month, now.day, 6);
    brevetMeta = BmBrevetMeta(
      distanceKm: matched.km,
      startTime: startTime,
      timeLimitHours: matched.limitHours,
    );
  }
  await saveBrevetMeta(brevetMeta);

  if (trackPoints.isNotEmpty) {
    final encoded = encodePolyline(trackPoints);
    await saveRouteEncoded(encoded);
    await saveTrackElevations(result.trackElevations);
    await markInitialRouteShown();
  }

  final nameToSave =
      (result.metadataName != null && result.metadataName!.isNotEmpty)
          ? result.metadataName!
          : (importFilename?.trim().isNotEmpty == true
              ? importFilename!.trim()
              : null);
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

  // start / finish を分離
  final startWpt = visibleWpts.cast<GpxPoi?>().firstWhere(
        (w) => w?.type?.trim().toLowerCase() == 'start',
        orElse: () => null,
      );
  final finishWpt = visibleWpts.cast<GpxPoi?>().firstWhere(
        (w) => w?.type?.trim().toLowerCase() == 'finish',
        orElse: () => null,
      );
  final otherWpts = visibleWpts
      .where((w) =>
          w.type?.trim().toLowerCase() != 'start' &&
          w.type?.trim().toLowerCase() != 'finish')
      .toList();

  // UserPoi に変換
  final otherPois = otherWpts
      .map((w) =>
          _gpxPoiToUserPoi(w, trackPoints: trackPoints, brevetMeta: brevetMeta))
      .toList();

  // start/finish: 明示的な wpt があればそれを使い、なければ常に自動生成
  final startPoi = startWpt != null
      ? _gpxPoiToUserPoi(startWpt,
          trackPoints: trackPoints, brevetMeta: brevetMeta)
      : (trackPoints.isNotEmpty
          ? _createStartPoi(trackPoints.first, brevetMeta)
          : null);

  final finishPoi = finishWpt != null
      ? _gpxPoiToUserPoi(finishWpt,
          trackPoints: trackPoints, brevetMeta: brevetMeta)
      : (trackPoints.isNotEmpty
          ? _createFinishPoi(trackPoints.last, totalDistanceKm, brevetMeta)
          : null);

  final userPois = [
    if (startPoi != null) startPoi,
    ...otherPois,
    if (finishPoi != null) finishPoi,
  ];

  await saveUserPois(userPois);

  return GpxImportResult(
    trackPoints: trackPoints,
    userPois: userPois,
    gpxDotWaypoints: dotWpts,
    trackElevations: trackPoints.isNotEmpty ? result.trackElevations : null,
    brevetMeta: brevetMeta,
  );
}

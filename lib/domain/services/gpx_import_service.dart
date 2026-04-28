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
  List<double?>? trackElevations,
  required BmBrevetMeta brevetMeta,
  required double totalRouteKm,
}) {
  final rawName = poi.name ?? '';
  final parsed = _parseNameAndKm(rawName);
  double? km = parsed.km;

  // 最近傍インデックスを一度求めて km 計算と獲得標高計算の両方に使う
  int? nearestIdx;
  if (trackPoints.isNotEmpty) {
    nearestIdx = nearestTrackIndex(trackPoints, poi.position);
    km ??= distanceAlongTrackFromStart(trackPoints, nearestIdx) / 1000;
  }

  // 獲得標高は bmPoiExt の有無にかかわらず計算（到着時刻推定で使う）
  final elevGain = (trackElevations != null &&
          trackElevations.isNotEmpty &&
          nearestIdx != null)
      ? elevationGainBetweenIndices(trackElevations, 0, nearestIdx)
      : 0.0;

  final gpxTypeLower = poi.type?.trim().toLowerCase() ?? '';
  final BmPoiExtension bmExt;
  if (poi.bmPoiExt != null) {
    final ext = poi.bmPoiExt!;
    if (gpxTypeLower == 'start') {
      bmExt = BmPoiExtension(
        type: ext.type,
        distanceKm: ext.distanceKm,
        schedule: BmSchedule(
          arrival: ext.schedule.arrival,
          departure: brevetMeta.startTime,
          close: ext.schedule.close,
          result: ext.schedule.result,
        ),
      );
    } else if (gpxTypeLower == 'finish') {
      final computedClose = _finishCloseFromBrevetMeta(
        brevetMeta,
        totalRouteKm: totalRouteKm,
      );
      final close = ext.schedule.close ??
          computedClose ??
          (totalRouteKm >= kMinRouteKmForFinishClose
              ? ext.schedule.arrival
              : null);
      final arrival = ext.schedule.arrival ??
          _estimateArrival(
            startTime: brevetMeta.startTime,
            distanceKm: km ?? ext.distanceKm,
            elevationGainM: elevGain,
          );
      bmExt = BmPoiExtension(
        type: ext.type,
        distanceKm: ext.distanceKm,
        schedule: BmSchedule(
          arrival: arrival,
          departure: ext.schedule.departure,
          close: close,
          result: ext.schedule.result,
        ),
      );
    } else if (gpxTypeLower != 'finish' &&
        ext.schedule.arrival == null &&
        ext.schedule.departure == null) {
      // arrival/departure が未設定：到着時刻を推定して設定する
      final arrival = _estimateArrival(
        startTime: brevetMeta.startTime,
        distanceKm: km ?? ext.distanceKm,
        elevationGainM: elevGain,
      );
      bmExt = BmPoiExtension(
        type: ext.type,
        distanceKm: ext.distanceKm,
        schedule: BmSchedule(
          arrival: arrival,
          departure: arrival?.add(const Duration(minutes: 15)),
          close: ext.schedule.close,
          result: ext.schedule.result,
        ),
      );
    } else {
      bmExt = ext;
    }
  } else {
    bmExt = _defaultBmPoiExtension(
      poiType: gpxTypeLower.isNotEmpty
          ? gpxTypeLower
          : (poi.isCheckpoint ? 'checkpoint' : 'generic'),
      distanceKm: km ?? 0,
      brevetMeta: brevetMeta,
      totalRouteKm: totalRouteKm,
      elevationGainM: elevGain,
    );
  }

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

/// finish のクローズ＝走行日スタート＋ [BmBrevetMeta.timeLimitHours]。
/// ルート全長 [totalRouteKm] が [kMinRouteKmForFinishClose] 未満のときは [null]。
/// [BmBrevetMeta.startTime] が null の場合のみ [DateTime.now]（UTC）を仮の起点にする
///（通常はインポート前に 6:00 既定の [brevetMeta.startTime] が入る）。
DateTime? _finishCloseFromBrevetMeta(
  BmBrevetMeta brevetMeta, {
  required double totalRouteKm,
}) {
  if (totalRouteKm < kMinRouteKmForFinishClose) return null;
  if (brevetMeta.timeLimitHours <= 0) return null;
  final limitDuration =
      Duration(minutes: (brevetMeta.timeLimitHours * 60).round());
  final ref = brevetMeta.startTime ?? DateTime.now().toUtc();
  return ref.add(limitDuration);
}

/// 走行日未設定時のスタート日時。POI 追加前フロー（settings_menu）と同じく当日ローカル 6:00 を UTC に直した値。
DateTime _defaultImportStartTime() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, 6).toUtc();
}


/// スタートから [distanceKm] km・[elevationGainM] m 登りの地点への到着予定時刻を返す。
/// 速度モデル: 基本 20 km/h + 登り 800 m/h（13.3 m/分）。
DateTime? _estimateArrival({
  required DateTime? startTime,
  required double distanceKm,
  required double elevationGainM,
}) {
  if (startTime == null) return null;
  const baseSpeedKmh = 20.0;
  const climbRateMph = 800.0;
  final raw =
      distanceKm / baseSpeedKmh * 60 + elevationGainM / climbRateMph * 60;
  // 15分単位に丸める
  final minutes = (raw / 15).floor() * 15;
  return startTime.add(Duration(minutes: minutes));
}

/// POI 種別に応じた既定の [BmPoiExtension] を生成する。
BmPoiExtension _defaultBmPoiExtension({
  required String poiType,
  required double distanceKm,
  required BmBrevetMeta brevetMeta,
  required double totalRouteKm,
  double elevationGainM = 0,
}) {
  final BmSchedule schedule;
  switch (poiType) {
    case 'start':
      schedule = BmSchedule(
        departure: brevetMeta.startTime,
      );
      break;
    case 'finish':
      final finishArrival = _estimateArrival(
        startTime: brevetMeta.startTime,
        distanceKm: distanceKm,
        elevationGainM: elevationGainM,
      );
      schedule = BmSchedule(
        arrival: finishArrival,
        close: _finishCloseFromBrevetMeta(
          brevetMeta,
          totalRouteKm: totalRouteKm,
        ),
      );
      break;
    default:
      final arrival = _estimateArrival(
        startTime: brevetMeta.startTime,
        distanceKm: distanceKm,
        elevationGainM: elevationGainM,
      );
      schedule = BmSchedule(
        arrival: arrival,
        departure: arrival?.add(const Duration(minutes: 15)),
      );
  }

  return BmPoiExtension(
    type: poiType,
    schedule: schedule,
    distanceKm: distanceKm,
  );
}

/// スタート POI を新規作成する（GPX にスタート wpt がない場合）。
UserPoi _createStartPoi(
  LatLng position,
  BmBrevetMeta brevetMeta, {
  required double totalRouteKm,
}) {
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
      totalRouteKm: totalRouteKm,
    ),
  );
}

/// ゴール POI を新規作成する（GPX にゴール wpt がない場合）。
UserPoi _createFinishPoi(
  LatLng position,
  double totalDistanceKm,
  BmBrevetMeta brevetMeta, {
  double elevationGainM = 0,
}) {
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
      totalRouteKm: totalDistanceKm,
      elevationGainM: elevationGainM,
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
  BmBrevetMeta brevetMeta;
  if (result.brevetMeta != null) {
    brevetMeta = result.brevetMeta!;
  } else {
    final matched = matchBrevetDistance(totalDistanceKm);
    brevetMeta = BmBrevetMeta(
      distanceKm: matched.km,
      timeLimitHours: matched.limitHours,
    );
  }
  if (brevetMeta.startTime == null) {
    brevetMeta = BmBrevetMeta(
      distanceKm: brevetMeta.distanceKm,
      startTime: _defaultImportStartTime(),
      timeLimitHours: brevetMeta.timeLimitHours,
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

  final trackElevations = result.trackElevations;

  // UserPoi に変換
  final otherPois = otherWpts
      .map(
        (w) => _gpxPoiToUserPoi(
          w,
          trackPoints: trackPoints,
          trackElevations: trackElevations,
          brevetMeta: brevetMeta,
          totalRouteKm: totalDistanceKm,
        ),
      )
      .toList();

  // start/finish: 明示的な wpt があればそれを使い、なければ常に自動生成
  final startPoi = startWpt != null
      ? _gpxPoiToUserPoi(
          startWpt,
          trackPoints: trackPoints,
          trackElevations: trackElevations,
          brevetMeta: brevetMeta,
          totalRouteKm: totalDistanceKm,
        )
      : (trackPoints.isNotEmpty
          ? _createStartPoi(
              trackPoints.first,
              brevetMeta,
              totalRouteKm: totalDistanceKm,
            )
          : null);

  final totalElevGain = trackElevations.isNotEmpty
      ? elevationGainBetweenIndices(trackElevations, 0, trackPoints.length - 1)
      : 0.0;

  final finishPoi = finishWpt != null
      ? _gpxPoiToUserPoi(
          finishWpt,
          trackPoints: trackPoints,
          trackElevations: trackElevations,
          brevetMeta: brevetMeta,
          totalRouteKm: totalDistanceKm,
        )
      : (trackPoints.isNotEmpty
          ? _createFinishPoi(
              trackPoints.last,
              totalDistanceKm,
              brevetMeta,
              elevationGainM: totalElevGain,
            )
          : null);

  final userPois = UserPoi.orderedForDetailSheet([
    if (startPoi != null) startPoi,
    ...otherPois,
    if (finishPoi != null) finishPoi,
  ]);

  await saveUserPois(userPois);

  return GpxImportResult(
    trackPoints: trackPoints,
    userPois: userPois,
    gpxDotWaypoints: dotWpts,
    trackElevations: trackPoints.isNotEmpty ? result.trackElevations : null,
    brevetMeta: brevetMeta,
  );
}

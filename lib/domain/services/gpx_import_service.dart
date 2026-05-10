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

/// `<extensions><bm:poi><bm:type>` がある場合は、アプリの [UserPoiType] ルールに沿って種別を決める。
///
/// - `checkpoint` … [UserPoiType.fromGpxTag] と同様、`<cmt>photo</cmt>` ならフォト CP
/// - `generic` …標準 GPX の `<type>` / `<cmt>` で [UserPoiType.fromGpxTag]
/// - それ以外の bm 種別（例: `hotel`）…その文字列を GPX [type] 相当として解釈
UserPoiType _userPoiTypeForImportedWaypoint(GpxPoi poi) {
  final ext = poi.bmPoiExt;
  if (ext != null) {
    final bmType = ext.type.trim().toLowerCase();
    if (bmType == GpxPoiTag.typeStart || bmType == GpxPoiTag.typeFinish) {
      return UserPoiType.information;
    }
    if (bmType == GpxPoiTag.checkpoint.type) {
      final cmtLower = poi.cmt?.trim().toLowerCase() ?? '';
      return cmtLower == GpxPoiTag.photo.cmt
          ? UserPoiType.photo
          : UserPoiType.checkpoint;
    }
    if (bmType == GpxPoiTag.information.type) {
      return UserPoiType.fromGpxTag(type: poi.type, cmt: poi.cmt);
    }
    return UserPoiType.fromGpxTag(type: bmType, cmt: poi.cmt);
  }
  return UserPoiType.fromGpxTag(type: poi.type, cmt: poi.cmt);
}

/// GpxPoi を UserPoi に変換する（Dot 以外のみ）。
/// `<extensions><bm:poi>` がある場合は GPX の内容をそのまま用い、沿線距離・時刻の自動推定はしない。
/// 拡張が無い外部 GPX では、[brevetMeta] とトラックから距離・到着/出発を推定する。
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

  final hasBmExtensions = poi.bmPoiExt != null;
  int? nearestIdx;

  if (!hasBmExtensions && trackPoints.isNotEmpty) {
    nearestIdx = nearestTrackIndex(trackPoints, poi.position);
    km ??= distanceAlongTrackFromStart(trackPoints, nearestIdx) / 1000;
  }

  final elevGain = (!hasBmExtensions &&
          trackElevations != null &&
          trackElevations.isNotEmpty &&
          nearestIdx != null)
      ? elevationGainBetweenIndices(trackElevations, 0, nearestIdx)
      : 0.0;

  final gpxTypeLower = poi.type?.trim().toLowerCase() ?? '';
  final mappedUserPoiType = _userPoiTypeForImportedWaypoint(poi);

  final BmPoiExtension bmExt;
  if (hasBmExtensions) {
    final ext = poi.bmPoiExt!;
    if (parsed.km == null && poi.bmRouteInfoInGpx) {
      km = ext.distanceKm;
    }
    final dKm = poi.bmRouteInfoInGpx ? ext.distanceKm : (km ?? 0);
    bmExt = BmPoiExtension(
      type: ext.type,
      distanceKm: dKm,
      schedule: ext.schedule,
      displayOrder: ext.displayOrder,
    );
  } else {
    final fallbackBmType = mappedUserPoiType.defaultBmPoiType;
    bmExt = _defaultBmPoiExtension(
      poiType: gpxTypeLower.isNotEmpty ? gpxTypeLower : fallbackBmType,
      distanceKm: km ?? 0,
      brevetMeta: brevetMeta,
      totalRouteKm: totalRouteKm,
      elevationGainM: elevGain,
    );
  }

  return UserPoi(
    type: mappedUserPoiType.value,
    km: km,
    title: parsed.title,
    body: poi.description ?? '',
    url: poi.linkHref,
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
  return estimateArrivalFromRouteStart(
    brevetStartTimeUtc: startTime,
    distanceKm: distanceKm,
    elevationGainFromStartMeters: elevationGainM,
  );
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
    case GpxPoiTag.typeStart:
      schedule = BmSchedule(
        departure: brevetMeta.startTime,
      );
      break;
    case GpxPoiTag.typeFinish:
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
    type: UserPoiType.information.value,
    km: 0,
    title: 'Start',
    body: '',
    lat: position.latitude,
    lng: position.longitude,
    bmExt: _defaultBmPoiExtension(
      poiType: GpxPoiTag.typeStart,
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
    type: UserPoiType.information.value,
    km: totalDistanceKm,
    title: 'Goal',
    body: '',
    lat: position.latitude,
    lng: position.longitude,
    bmExt: _defaultBmPoiExtension(
      poiType: GpxPoiTag.typeFinish,
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
        (w) => GpxPoiTag.isStartType(w?.type),
        orElse: () => null,
      );
  final finishWpt = visibleWpts.cast<GpxPoi?>().firstWhere(
        (w) => GpxPoiTag.isFinishType(w?.type),
        orElse: () => null,
      );
  final otherWpts =
      visibleWpts.where((w) => !GpxPoiTag.isStartOrFinishType(w.type)).toList();

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

  final mergeCandidates = <UserPoi>[
    if (startPoi != null) startPoi,
    ...otherPois,
    if (finishPoi != null) finishPoi,
  ];

  final List<UserPoi> userPois;
  final allHaveDisplayOrder = mergeCandidates.isNotEmpty &&
      mergeCandidates.every((p) => p.bmExt?.displayOrder != null);
  if (allHaveDisplayOrder) {
    userPois = List<UserPoi>.from(mergeCandidates)
      ..sort((a, b) =>
          a.bmExt!.displayOrder!.compareTo(b.bmExt!.displayOrder!));
  } else {
    userPois = UserPoi.orderedForDetailSheet(mergeCandidates);
  }

  await saveUserPois(userPois);

  return GpxImportResult(
    trackPoints: trackPoints,
    userPois: userPois,
    gpxDotWaypoints: dotWpts,
    trackElevations: trackPoints.isNotEmpty ? result.trackElevations : null,
    brevetMeta: brevetMeta,
  );
}

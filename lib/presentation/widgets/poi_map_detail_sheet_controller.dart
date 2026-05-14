import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/parsers/gpx_parser.dart';
import '../../data/repositories/first_launch_repository.dart';
import '../../domain/models/brevet_distances.dart';
import '../../domain/models/user_poi.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/map_utils.dart';
import '../providers/providers.dart';
import 'poi_detail_sheet.dart';

/// ボトムシート内の POI 表示順。
abstract final class PoiMapMarkerOrder {
  PoiMapMarkerOrder._();

  /// Dot は除外。チェックポイント → インフォ。
  static List<GpxPoi> gpxPois(List<GpxPoi> pois) => [
        for (final p in pois)
          if (!p.isGpxDotType && p.isCheckpoint) p,
        for (final p in pois)
          if (!p.isGpxDotType && !p.isCheckpoint) p,
      ];

  /// 呼び出し元の [List] 順（[mapStateProvider.userPois] の永続化順。編集画面のドラッグで変更可）を使う。
  static List<UserPoi> userPois(List<UserPoi> pois) => List<UserPoi>.from(pois);
}

bool _sameGpxPoi(GpxPoi a, GpxPoi b) =>
    (a.lat - b.lat).abs() < 1e-9 && (a.lng - b.lng).abs() < 1e-9;

double? _elapsedHoursFromBrevetStart(DateTime? brevetStartUtc, DateTime? arrival) {
  if (brevetStartUtc == null || arrival == null) return null;
  final h =
      arrival.difference(brevetStartUtc).inMicroseconds / 3600000000.0;
  if (!h.isFinite) return null;
  return h < 0 ? 0.0 : h;
}

/// 時刻チャートの原点。到着推定は [BmSchedule.departure]/[BmSchedule.arrival] と
/// [estimateArrivalFromRouteStart] でスタート地点の出発を基準にしているため、
/// メタの `startTime` だけだとデータ不整合で経過が極端に大きくなることがある。
DateTime? _chartBrevetStartUtcFromGpxPois(
  List<GpxPoi> ordered,
  DateTime? metaStart,
) {
  for (final p in ordered) {
    if (GpxPoiTag.isStartType(p.bmPoiExt?.type)) {
      final s = p.bmPoiExt?.schedule;
      return s?.departure ?? s?.arrival ?? metaStart;
    }
  }
  return metaStart;
}

DateTime? _chartBrevetStartUtcFromUserPois(
  List<UserPoi> ordered,
  DateTime? metaStart,
) {
  for (final p in ordered) {
    if (GpxPoiTag.isStartType(p.bmExt?.type)) {
      final s = p.bmExt?.schedule;
      return s?.departure ?? s?.arrival ?? metaStart;
    }
  }
  return metaStart;
}

double? _totalRouteKm(List<LatLng> trackPoints) {
  if (trackPoints.length < 2) return null;
  final m = distanceAlongTrackFromStart(
    trackPoints,
    trackPoints.length - 1,
  );
  final km = m / 1000.0;
  if (!km.isFinite || km <= 0) return null;
  return km;
}

/// 地図上の POI タップから詳細ボトムシート表示・シート内移動時の地図追従までを担当する。
class PoiMapDetailSheetController {
  PoiMapDetailSheetController(this._ref);

  final WidgetRef _ref;

  PoiElevationOnDemand? _elevationOnDemandFor(
    List<LatLng> trackPoints,
    List<double?> elevations,
    List<LatLng> poiPositions,
    int poiIndex,
    int distanceUnit, {
    List<bool>? poiHasDistanceKm,
    List<double?>? poiKmAlongRoute,
    String? chartMetadataName,
    double? chartTimeLimitHours,
  }) {
    if (trackPoints.length < 2) return null;
    return PoiElevationOnDemand(
      trackPoints: trackPoints,
      elevations: elevations,
      poiPositions: poiPositions,
      poiIndex: poiIndex,
      distanceUnit: distanceUnit,
      poiHasDistanceKm: poiHasDistanceKm,
      poiKmAlongRoute: poiKmAlongRoute,
      chartMetadataName: chartMetadataName,
      chartTimeLimitHours: chartTimeLimitHours,
    );
  }

  Future<
      ({
        String? gpxBasename,
        double? timeLimitHours,
        DateTime? brevetStartUtc,
      })> _loadStartPoiElevationChartFields() async {
    final routeBasename = await loadGpxImportBasename();
    final meta = await loadBrevetMeta();
    final trimmed = routeBasename?.trim();
    final name = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    final rawH = meta?.timeLimitHours ?? 0;
    final hours =
        (rawH > 0 && rawH.isFinite) ? rawH : null;
    return (
      gpxBasename: name,
      timeLimitHours: hours,
      brevetStartUtc: meta?.startTime,
    );
  }

  /// 出走日・制限時間・スタートが揃うとき、POI シート上段の経過時間チャート。
  PoiSheetTimeChart? _poiElapsedTimeChart({
    required DateTime? brevetStartUtc,
    required double? timeLimitHours,
    double? routeKm,
    required DateTime? arrival,
    required DateTime? departure,
    required bool isRouteStartPoi,
  }) {
    if (brevetStartUtc == null ||
        timeLimitHours == null ||
        timeLimitHours <= 0 ||
        !timeLimitHours.isFinite) {
      return null;
    }
    // 経過時間の意味を持たせるため、スタート以外は到着が無いときチャートを出さない。
    // スタートは出発のみ設定が通常のため例外。
    if (!isRouteStartPoi && arrival == null) {
      return null;
    }
    final axisTickStepHours = brevetTimeChartAxisTickStepHours(
      timeLimitHours,
      routeKm: routeKm,
    );
    // スタート POI も出発のみ設定されているのが通常。軸原点と同じ基準にする。
    final instant = isRouteStartPoi
        ? (departure ?? arrival)
        : (arrival ?? departure);
    final elapsed = _elapsedHoursFromBrevetStart(brevetStartUtc, instant);
    return PoiSheetTimeChart(
      brevetStartUtc: brevetStartUtc,
      timeLimitHours: timeLimitHours,
      axisTickStepHours: axisTickStepHours,
      elapsedHoursFromStart: elapsed,
      drawElapsedBar: !isRouteStartPoi,
    );
  }

  Future<void> animateToPoiPreservingZoom(LatLng position) async {
    final mapCtrl = _ref.read(cameraControllerProvider);
    if (mapCtrl == null) return;
    final z = mapCtrl.camera.zoom;
    await _ref.read(cameraControllerProvider.notifier).animateTo(
          position,
          zoom: z,
        );
  }

  Future<void> handleGpxPoiTap(
    BuildContext context,
    GpxPoi poi,
    bool Function() isMounted,
  ) async {
    await animateToPoiPreservingZoom(poi.position);
    if (!isMounted() || !context.mounted) return;
    final unit = _ref.read(distanceUnitProvider);
    final ms = _ref.read(mapStateProvider);
    final ordered = PoiMapMarkerOrder.gpxPois(ms.gpxPois);
    final canNavigateInSheet = ordered.length >= 2;
    final trackPoints = ms.savedRoutePoints ?? const <LatLng>[];
    final elevations = ms.savedTrackElevations ?? const <double?>[];
    if (canNavigateInSheet) {
      final positions = ordered.map((p) => p.position).toList(growable: false);
      String? startMetaName;
      double? startTimeLimitHours;
      final needStartHeader = trackPoints.length >= 2 &&
          ordered.any((p) => GpxPoiTag.isStartType(p.bmPoiExt?.type));
      final fields = await _loadStartPoiElevationChartFields();
      if (!isMounted() || !context.mounted) return;
      if (needStartHeader) {
        startMetaName = fields.gpxBasename;
        startTimeLimitHours = fields.timeLimitHours;
      }
      final chartBrevetStartUtc =
          _chartBrevetStartUtcFromGpxPois(ordered, fields.brevetStartUtc);
      final entries = <PoiSheetEntry>[];
      for (var i = 0; i < ordered.length; i++) {
        final isStart = GpxPoiTag.isStartType(ordered[i].bmPoiExt?.type);
        final sched = ordered[i].bmPoiExt?.schedule;
        entries.add(
          PoiSheetEntry(
            name: ordered[i].name,
            description: ordered[i].description,
            position: ordered[i].position,
            arrival: sched?.arrival,
            departure: sched?.departure,
            close: sched?.close,
            timeChart: _poiElapsedTimeChart(
              brevetStartUtc: chartBrevetStartUtc,
              timeLimitHours: fields.timeLimitHours,
              routeKm: _totalRouteKm(trackPoints),
              arrival: sched?.arrival,
              departure: sched?.departure,
              isRouteStartPoi: isStart,
            ),
            elevationOnDemand: _elevationOnDemandFor(
              trackPoints,
              elevations,
              positions,
              i,
              unit,
              chartMetadataName: isStart ? startMetaName : null,
              chartTimeLimitHours: isStart ? startTimeLimitHours : null,
            ),
            distanceUnit: unit,
            isRouteStartPoi: i == 0,
          ),
        );
      }
      final idx = ordered.indexWhere((p) => _sameGpxPoi(p, poi));
      final safeIdx = idx >= 0 ? idx : 0;
      showPoiDetailSheet(
        context,
        entries: entries,
        initialIndex: safeIdx,
        onCenterOnPoi: (pos) {
          animateToPoiPreservingZoom(pos);
        },
      );
    } else {
      final fields = await _loadStartPoiElevationChartFields();
      String? startMetaName;
      double? startTimeLimitHours;
      if (trackPoints.length >= 2 &&
          GpxPoiTag.isStartType(poi.bmPoiExt?.type)) {
        startMetaName = fields.gpxBasename;
        startTimeLimitHours = fields.timeLimitHours;
      }
      if (!isMounted() || !context.mounted) return;
      final gpxOrderedForChart = PoiMapMarkerOrder.gpxPois(ms.gpxPois);
      final chartBrevetStartUtc =
          _chartBrevetStartUtcFromGpxPois(gpxOrderedForChart, fields.brevetStartUtc);
      final sched = poi.bmPoiExt?.schedule;
      final isStart = GpxPoiTag.isStartType(poi.bmPoiExt?.type);
      showPoiDetailSheet(
        context,
        entries: [
          PoiSheetEntry(
            name: poi.name,
            description: poi.description,
            position: poi.position,
            arrival: sched?.arrival,
            departure: sched?.departure,
            close: sched?.close,
            timeChart: _poiElapsedTimeChart(
              brevetStartUtc: chartBrevetStartUtc,
              timeLimitHours: fields.timeLimitHours,
              routeKm: _totalRouteKm(trackPoints),
              arrival: sched?.arrival,
              departure: sched?.departure,
              isRouteStartPoi: isStart,
            ),
            elevationOnDemand: _elevationOnDemandFor(
              trackPoints,
              elevations,
              <LatLng>[poi.position],
              0,
              unit,
              chartMetadataName: startMetaName,
              chartTimeLimitHours: startTimeLimitHours,
            ),
            distanceUnit: unit,
            isRouteStartPoi: isStart,
          ),
        ],
      );
    }
  }

  Future<void> handleUserPoiTap(
    BuildContext context,
    UserPoi poi,
    bool Function() isMounted,
  ) async {
    await animateToPoiPreservingZoom(poi.position);
    if (!isMounted() || !context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final unit = _ref.read(distanceUnitProvider);

    String titleFor(UserPoi p) => p.title.isEmpty ? l10n.titleNone : p.title;

    String? distanceFor(UserPoi p) =>
        p.km != null ? formatDistance(p.km!, unit) : null;

    final ms = _ref.read(mapStateProvider);
    final ordered = PoiMapMarkerOrder.userPois(ms.userPois);
    final canNavigateInSheet = ordered.length >= 2;
    final trackPoints = ms.savedRoutePoints ?? const <LatLng>[];
    final elevations = ms.savedTrackElevations ?? const <double?>[];

    if (canNavigateInSheet) {
      final cached = ms.cachedPoiElevationGains;
      final rawGains = (cached != null && cached.length == ordered.length)
          ? cached
          : List<double?>.filled(ordered.length, null);

      final positions =
          ordered.map((p) => LatLng(p.lat, p.lng)).toList(growable: false);
      final poiHasKm =
          ordered.map((p) => p.km != null && !p.isNote).toList(growable: false);
      final poiKmAlong =
          ordered.map<double?>((p) => p.km).toList(growable: false);

      String? startMetaName;
      double? startTimeLimitHours;
      final needStartHeader = trackPoints.length >= 2 &&
          ordered.any(
            (p) =>
                GpxPoiTag.isStartType(p.bmExt?.type) &&
                p.km != null &&
                !p.isNote,
          );
      final fields = await _loadStartPoiElevationChartFields();
      if (!isMounted() || !context.mounted) return;
      if (needStartHeader) {
        startMetaName = fields.gpxBasename;
        startTimeLimitHours = fields.timeLimitHours;
      }

      final chartBrevetStartUtc =
          _chartBrevetStartUtcFromUserPois(ordered, fields.brevetStartUtc);
      final entries = <PoiSheetEntry>[];
      for (var i = 0; i < ordered.length; i++) {
        final hasKmForSegment = poiHasKm[i];
        final sched = ordered[i].bmExt?.schedule;
        final isStartType = GpxPoiTag.isStartType(ordered[i].bmExt?.type);
        entries.add(
          PoiSheetEntry(
            name: titleFor(ordered[i]),
            distance: distanceFor(ordered[i]),
            elevationGain: hasKmForSegment && rawGains[i] != null
                ? formatElevationChange(rawGains[i]!, unit)
                : null,
            description: ordered[i].body,
            url: ordered[i].url,
            position: ordered[i].position,
            arrival: sched?.arrival,
            departure: sched?.departure,
            close: sched?.close,
            timeChart: _poiElapsedTimeChart(
              brevetStartUtc: chartBrevetStartUtc,
              timeLimitHours: fields.timeLimitHours,
              routeKm: _totalRouteKm(trackPoints),
              arrival: sched?.arrival,
              departure: sched?.departure,
              isRouteStartPoi: isStartType,
            ),
            elevationOnDemand: hasKmForSegment
                ? _elevationOnDemandFor(
                    trackPoints,
                    elevations,
                    positions,
                    i,
                    unit,
                    poiHasDistanceKm: poiHasKm,
                    poiKmAlongRoute: poiKmAlong,
                    chartMetadataName: isStartType ? startMetaName : null,
                    chartTimeLimitHours: isStartType ? startTimeLimitHours : null,
                  )
                : null,
            distanceUnit: unit,
            isRouteStartPoi: i == 0,
          ),
        );
      }
      final idx = UserPoi.indexInList(ordered, poi);
      final safeIdx = idx >= 0 ? idx : 0;
      showPoiDetailSheet(
        context,
        entries: entries,
        initialIndex: safeIdx,
        onCenterOnPoi: (pos) {
          animateToPoiPreservingZoom(pos);
        },
      );
    } else {
      final fields = await _loadStartPoiElevationChartFields();
      String? startMetaName;
      double? startTimeLimitHours;
      if (trackPoints.length >= 2 &&
          GpxPoiTag.isStartType(poi.bmExt?.type) &&
          poi.km != null &&
          !poi.isNote) {
        startMetaName = fields.gpxBasename;
        startTimeLimitHours = fields.timeLimitHours;
      }
      if (!isMounted() || !context.mounted) return;
      final allUserForChart =
          PoiMapMarkerOrder.userPois(ms.userPois);
      final chartBrevetStartUtc =
          _chartBrevetStartUtcFromUserPois(allUserForChart, fields.brevetStartUtc);
      final sched = poi.bmExt?.schedule;
      final isStartType = GpxPoiTag.isStartType(poi.bmExt?.type);
      showPoiDetailSheet(
        context,
        entries: [
          PoiSheetEntry(
            name: titleFor(poi),
            distance: distanceFor(poi),
            elevationGain: null,
            description: poi.body,
            url: poi.url,
            position: poi.position,
            arrival: sched?.arrival,
            departure: sched?.departure,
            close: sched?.close,
            timeChart: _poiElapsedTimeChart(
              brevetStartUtc: chartBrevetStartUtc,
              timeLimitHours: fields.timeLimitHours,
              routeKm: _totalRouteKm(trackPoints),
              arrival: sched?.arrival,
              departure: sched?.departure,
              isRouteStartPoi: isStartType,
            ),
            elevationOnDemand: poi.km != null && !poi.isNote
                ? _elevationOnDemandFor(
                    trackPoints,
                    elevations,
                    <LatLng>[LatLng(poi.lat, poi.lng)],
                    0,
                    unit,
                    poiHasDistanceKm: const [true],
                    poiKmAlongRoute: <double?>[poi.km],
                    chartMetadataName: startMetaName,
                    chartTimeLimitHours: startTimeLimitHours,
                  )
                : null,
            distanceUnit: unit,
            isRouteStartPoi: isStartType,
          ),
        ],
      );
    }
  }
}

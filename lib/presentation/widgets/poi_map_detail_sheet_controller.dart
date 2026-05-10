import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/parsers/gpx_parser.dart';
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
  }) {
    if (trackPoints.length < 2) return null;
    return PoiElevationOnDemand(
      trackPoints: trackPoints,
      elevations: elevations,
      poiPositions: poiPositions,
      poiIndex: poiIndex,
      distanceUnit: distanceUnit,
      poiHasDistanceKm: poiHasDistanceKm,
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
      final entries = <PoiSheetEntry>[];
      for (var i = 0; i < ordered.length; i++) {
        entries.add(
          PoiSheetEntry(
            name: ordered[i].name,
            description: ordered[i].description,
            position: ordered[i].position,
            close: ordered[i].bmPoiExt?.schedule.close,
            elevationOnDemand: _elevationOnDemandFor(
              trackPoints,
              elevations,
              positions,
              i,
              unit,
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
      showPoiDetailSheet(
        context,
        entries: [
          PoiSheetEntry(
            name: poi.name,
            description: poi.description,
            position: poi.position,
            close: poi.bmPoiExt?.schedule.close,
            elevationOnDemand: _elevationOnDemandFor(
              trackPoints,
              elevations,
              <LatLng>[poi.position],
              0,
              unit,
            ),
            distanceUnit: unit,
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
          ordered.map((p) => p.km != null).toList(growable: false);

      final entries = <PoiSheetEntry>[];
      for (var i = 0; i < ordered.length; i++) {
        final hasKm = poiHasKm[i];
        entries.add(
          PoiSheetEntry(
            name: titleFor(ordered[i]),
            distance: distanceFor(ordered[i]),
            elevationGain: hasKm && rawGains[i] != null
                ? formatElevationChange(rawGains[i]!, unit)
                : null,
            description: ordered[i].body,
            url: ordered[i].url,
            position: ordered[i].position,
            arrival: ordered[i].bmExt?.schedule.arrival,
            departure: ordered[i].bmExt?.schedule.departure,
            close: ordered[i].bmExt?.schedule.close,
            elevationOnDemand: hasKm
                ? _elevationOnDemandFor(
                    trackPoints,
                    elevations,
                    positions,
                    i,
                    unit,
                    poiHasDistanceKm: poiHasKm,
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
            arrival: poi.bmExt?.schedule.arrival,
            departure: poi.bmExt?.schedule.departure,
            close: poi.bmExt?.schedule.close,
            elevationOnDemand: poi.km != null
                ? _elevationOnDemandFor(
                    trackPoints,
                    elevations,
                    <LatLng>[LatLng(poi.lat, poi.lng)],
                    0,
                    unit,
                    poiHasDistanceKm: const [true],
                  )
                : null,
            distanceUnit: unit,
          ),
        ],
      );
    }
  }
}

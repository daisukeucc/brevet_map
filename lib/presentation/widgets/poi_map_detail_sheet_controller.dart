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

  /// [UserPoi.orderedForDetailSheet] を参照。
  static List<UserPoi> userPois(List<UserPoi> pois) =>
      UserPoi.orderedForDetailSheet(pois);
}

bool _sameGpxPoi(GpxPoi a, GpxPoi b) =>
    (a.lat - b.lat).abs() < 1e-9 && (a.lng - b.lng).abs() < 1e-9;

bool _sameUserPoi(UserPoi a, UserPoi b) =>
    (a.lat - b.lat).abs() < 1e-9 && (a.lng - b.lng).abs() < 1e-9;

/// 地図上の POI タップから詳細ボトムシート表示・シート内移動時の地図追従までを担当する。
class PoiMapDetailSheetController {
  PoiMapDetailSheetController(this._ref);

  final WidgetRef _ref;

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
    final ms = _ref.read(mapStateProvider);
    final ordered = PoiMapMarkerOrder.gpxPois(ms.gpxPois);
    final canNavigateInSheet = ordered.length >= 2;
    if (canNavigateInSheet) {
      final entries = [
        for (final p in ordered)
          PoiSheetEntry(
            name: p.name,
            description: p.description,
            position: p.position,
          ),
      ];
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

    String titleFor(UserPoi p) =>
        p.title.isEmpty ? l10n.titleNone : p.title;

    String? distanceFor(UserPoi p) =>
        p.km != null ? formatDistance(p.km!, unit) : null;

    final ms = _ref.read(mapStateProvider);
    final ordered = PoiMapMarkerOrder.userPois(ms.userPois);
    final canNavigateInSheet = ordered.length >= 2;

    if (canNavigateInSheet) {
      final cached = ms.cachedPoiElevationGains;
      final elevationGains = (cached != null && cached.length == ordered.length)
          ? cached
          : List<String?>.filled(ordered.length, null);

      final entries = [
        for (var i = 0; i < ordered.length; i++)
          PoiSheetEntry(
            name: titleFor(ordered[i]),
            distance: distanceFor(ordered[i]),
            elevationGain: elevationGains[i],
            description: ordered[i].body,
            position: ordered[i].position,
          ),
      ];
      final idx = ordered.indexWhere((p) => _sameUserPoi(p, poi));
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
            position: poi.position,
          ),
        ],
      );
    }
  }
}

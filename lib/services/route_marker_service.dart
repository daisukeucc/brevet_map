import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../parsers/gpx_parser.dart';
import '../utils/map_utils.dart';
import 'marker_icon_service.dart';

/// 距離マーカーを表示するズームレベルの閾値。この値以上で拡大しているときに表示する。
const double distanceMarkerZoomThreshold = 9.0;

/// スタート・ゴール・POI の [Marker] セットを組み立てる。
/// [zoomLevel] を渡すと、[distanceMarkerZoomThreshold] 以上の場合のみ距離マーカーを表示する。
/// 距離マーカーはアイコン上に「50km」「100km」等のラベルを描画する。
/// [onPoiTap] は POI マーカータップ時に呼ばれる（例: ボトムシート表示）。
Future<Set<Marker>> buildRouteMarkers({
  required List<LatLng> routePoints,
  required List<GpxPoi> pois,
  required void Function(GpxPoi poi) onPoiTap,
  double? zoomLevel,
}) async {
  final showDistanceMarkers =
      zoomLevel == null || zoomLevel >= distanceMarkerZoomThreshold;
  final markers = <Marker>{};
  BitmapDescriptor? startIcon;
  BitmapDescriptor? goalIcon;
  BitmapDescriptor? poiIconOrange;
  BitmapDescriptor? poiIconCheckpoint;

  try {
    if (routePoints.isNotEmpty) {
      startIcon = await createRoundedSquareMarkerIcon(
        backgroundColor: Colors.green,
        isPlayIcon: true,
      );
      goalIcon = await createRoundedSquareMarkerIcon(
        backgroundColor: Colors.red,
        isPlayIcon: false,
      );
    }
    if (pois.isNotEmpty) {
      poiIconOrange = await createPoiInfoMarkerIcon();
      poiIconCheckpoint = await createPoiCheckpointMarkerIcon();
    }
  } catch (_) {
    return markers;
  }

  if (routePoints.isNotEmpty && startIcon != null && goalIcon != null) {
    final start = routePoints.first;
    final goal = routePoints.length > 1 ? routePoints.last : start;
    final isSamePoint = (start.latitude - goal.latitude).abs() < 1e-6 &&
        (start.longitude - goal.longitude).abs() < 1e-6;
    final startAnchor =
        isSamePoint ? const Offset(0, 0) : const Offset(0.5, 0.5);
    markers.add(Marker(
      markerId: const MarkerId('start'),
      position: start,
      icon: startIcon,
      anchor: startAnchor,
      zIndex: 2,
    ));
    markers.add(Marker(
      markerId: const MarkerId('goal'),
      position: goal,
      icon: goalIcon,
      anchor: const Offset(0.5, 0.5),
      zIndex: 1,
    ));

    if (showDistanceMarkers) {
      final distanceList =
          distanceMarkersAlongTrack(routePoints, intervalMeters: 50000);
      for (final m in distanceList) {
        final label = '${m.distanceKm.toInt()}km';
        try {
          final icon = await createDistanceMarkerIcon(label);
          markers.add(Marker(
            markerId: MarkerId('km_${m.distanceKm.toInt()}'),
            position: m.position,
            icon: icon,
            anchor: const Offset(0.25, 0.25),
            zIndex: 0,
          ));
        } catch (_) {
          // アイコン生成に失敗した場合はスキップ
        }
      }
    }
  }

  if (pois.isNotEmpty && poiIconOrange != null && poiIconCheckpoint != null) {
    for (var i = 0; i < pois.length; i++) {
      final poi = pois[i];
      final icon = poi.isControl ? poiIconCheckpoint : poiIconOrange;
      markers.add(Marker(
        markerId: MarkerId('poi_$i'),
        position: poi.position,
        icon: icon,
        anchor: const Offset(0.25, 0.25),
        zIndex: 0,
        onTap: () => onPoiTap(poi),
      ));
    }
  }

  return markers;
}

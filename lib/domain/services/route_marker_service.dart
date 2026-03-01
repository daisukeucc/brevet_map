import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/parsers/gpx_parser.dart';
import '../../utils/map_utils.dart';
import 'marker_icon_service.dart';

/// 距離マーカーを表示するズームレベルの閾値。この値以上で拡大しているときに表示する。
const double distanceMarkerZoomThreshold = 9.0;

/// スタート・ゴール・POI の [Marker] リストを組み立てる。
/// [zoomLevel] を渡すと、[distanceMarkerZoomThreshold] 以上の場合のみ距離マーカーを表示する。
/// [onPoiTap] は POI マーカータップ時に呼ばれる（例: ボトムシート表示）。
List<Marker> buildRouteMarkers({
  required List<LatLng> routePoints,
  required List<GpxPoi> pois,
  required void Function(GpxPoi poi) onPoiTap,
  double? zoomLevel,
}) {
  final showDistanceMarkers =
      zoomLevel == null || zoomLevel >= distanceMarkerZoomThreshold;
  final markers = <Marker>[];

  if (routePoints.isNotEmpty) {
    final start = routePoints.first;
    final goal = routePoints.length > 1 ? routePoints.last : start;
    final isSamePoint = (start.latitude - goal.latitude).abs() < 1e-6 &&
        (start.longitude - goal.longitude).abs() < 1e-6;
    final startAlignment =
        isSamePoint ? Alignment.topLeft : Alignment.center;

    markers.add(Marker(
      point: start,
      width: 44,
      height: 44,
      alignment: startAlignment,
      child: createRoundedSquareMarkerIcon(
        backgroundColor: Colors.green,
        isPlayIcon: true,
      ),
    ));
    markers.add(Marker(
      point: goal,
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: createRoundedSquareMarkerIcon(
        backgroundColor: Colors.red,
        isPlayIcon: false,
      ),
    ));

    if (showDistanceMarkers) {
      final distanceList =
          distanceMarkersAlongTrack(routePoints, intervalMeters: 50000);
      for (final m in distanceList) {
        final label = '${m.distanceKm.toInt()}km';
        markers.add(Marker(
          point: m.position,
          width: 48,
          height: 24,
          alignment: const Alignment(-0.5, -0.5),
          child: createDistanceMarkerIcon(label),
        ));
      }
    }
  }

  if (pois.isNotEmpty) {
    for (var i = 0; i < pois.length; i++) {
      final poi = pois[i];
      final icon =
          poi.isControl ? createPoiCheckpointMarkerIcon() : createPoiInfoMarkerIcon();
      markers.add(Marker(
        point: poi.position,
        width: 36,
        height: 36,
        alignment: const Alignment(-0.5, -0.5),
        child: GestureDetector(
          onTap: () => onPoiTap(poi),
          child: icon,
        ),
      ));
    }
  }

  return markers;
}

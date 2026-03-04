import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/parsers/gpx_parser.dart';
import '../../domain/models/user_poi.dart';
import '../../utils/map_utils.dart';
import 'marker_icon_service.dart';

/// 距離マーカーを表示するズームレベルの閾値。この値以上で拡大しているときに表示する。
const double distanceMarkerZoomThreshold = 9.0;

/// 50km をメートルに換算
const double _interval50kmMeters = 50000.0;

/// 50 mile をメートルに換算 (1 mile = 1609.344 m)
const double _interval50mileMeters = 50 * 1609.344;

const double _kmPerMile = 1.609344;

/// スタート・ゴール・POI の [Marker] セットを組み立てる。
/// [zoomLevel] を渡すと、[distanceMarkerZoomThreshold] 以上の場合のみ距離マーカーを表示する。
/// 距離マーカーはアイコン上に「50km」「100km」等のラベルを描画する。
/// [onPoiTap] は POI マーカータップ時に呼ばれる（例: ボトムシート表示）。
/// [distanceUnit] 0=km（50km間隔でNkm表示）, 1=mile（50mile間隔でNmi表示）
Future<Set<Marker>> buildRouteMarkers({
  required List<LatLng> routePoints,
  required List<GpxPoi> pois,
  required void Function(GpxPoi poi) onPoiTap,
  List<UserPoi> userPois = const [],
  void Function(UserPoi poi)? onUserPoiTap,
  double? zoomLevel,
  UserPoi? draggingPoi,
  void Function(LatLng)? onPoiDragEnd,
  int distanceUnit = 0,
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
    if (pois.isNotEmpty || userPois.isNotEmpty) {
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
      final intervalMeters =
          distanceUnit == 1 ? _interval50mileMeters : _interval50kmMeters;
      final distanceList = distanceMarkersAlongTrack(routePoints,
          intervalMeters: intervalMeters);
      for (var i = 0; i < distanceList.length; i++) {
        final m = distanceList[i];
        final label = distanceUnit == 1
            ? '${50 * (i + 1)}mi'
            : '${m.distanceKm.toInt()}km';
        final idSuffix =
            distanceUnit == 1 ? 50 * (i + 1) : m.distanceKm.toInt();
        try {
          final icon = await createDistanceMarkerIcon(label);
          markers.add(Marker(
            markerId: MarkerId('dist_${distanceUnit}_$idSuffix'),
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
        zIndex: 1,
        onTap: () => onPoiTap(poi),
      ));
    }
  }

  if (userPois.isNotEmpty &&
      poiIconOrange != null &&
      poiIconCheckpoint != null) {
    for (var i = 0; i < userPois.length; i++) {
      final poi = userPois[i];
      final icon = poi.isCheckpoint ? poiIconCheckpoint : poiIconOrange;
      final isDragging = draggingPoi != null &&
          poi.lat == draggingPoi.lat &&
          poi.lng == draggingPoi.lng;
      markers.add(Marker(
        markerId: MarkerId('user_poi_$i'),
        position: poi.position,
        icon: icon,
        anchor: const Offset(0.25, 0.25),
        zIndex: isDragging ? 10 : 1,
        draggable: isDragging,
        onDragEnd: isDragging ? (newPos) => onPoiDragEnd?.call(newPos) : null,
        onTap: isDragging ? null : () => onUserPoiTap?.call(poi),
      ));
    }
  }

  return markers;
}

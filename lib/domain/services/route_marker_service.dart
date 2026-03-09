import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

/// マーカー表示サイズ（論理ピクセル）
const double _markerSize = 72.0;

/// スタート・ゴール・POI の [Marker] リストを組み立てる。
Future<List<Marker>> buildRouteMarkers({
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
  final markers = <Marker>[];
  Widget? startIcon;
  Widget? goalIcon;
  Widget? poiIconOrange;
  Widget? poiIconCheckpoint;

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

  // 描画順: 距離マーカー → POI → ユーザー POI → ゴール → スタート（最前面）

  if (routePoints.isNotEmpty && showDistanceMarkers) {
    final intervalMeters =
        distanceUnit == 1 ? _interval50mileMeters : _interval50kmMeters;
    final distanceList = distanceMarkersAlongTrack(routePoints,
        intervalMeters: intervalMeters);
    for (var i = 0; i < distanceList.length; i++) {
      final m = distanceList[i];
      final label = distanceUnit == 1
          ? '${50 * (i + 1)}mi'
          : '${m.distanceKm.toInt()}km';
      try {
        final result = await createDistanceMarkerIcon(label);
        markers.add(Marker(
          point: m.position,
          width: result.width,
          height: result.height,
          alignment: Alignment.center,
          child: result.icon,
        ));
      } catch (_) {
        // アイコン生成に失敗した場合はスキップ
      }
    }
  }

  if (pois.isNotEmpty && poiIconOrange != null && poiIconCheckpoint != null) {
    for (var i = 0; i < pois.length; i++) {
      final poi = pois[i];
      final icon = poi.isControl ? poiIconCheckpoint! : poiIconOrange!;
      markers.add(Marker(
        point: poi.position,
        width: _markerSize,
        height: _markerSize,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => onPoiTap(poi),
          child: icon,
        ),
      ));
    }
  }

  if (userPois.isNotEmpty &&
      poiIconOrange != null &&
      poiIconCheckpoint != null) {
    for (var i = 0; i < userPois.length; i++) {
      final poi = userPois[i];
      final icon = poi.isCheckpoint ? poiIconCheckpoint! : poiIconOrange!;
      final isDragging = draggingPoi != null &&
          poi.lat == draggingPoi.lat &&
          poi.lng == draggingPoi.lng;
      markers.add(Marker(
        point: poi.position,
        width: _markerSize,
        height: _markerSize,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: isDragging ? null : () => onUserPoiTap?.call(poi),
          child: icon,
        ),
      ));
    }
  }

  if (routePoints.isNotEmpty && startIcon != null && goalIcon != null) {
    final start = routePoints.first;
    final goal = routePoints.length > 1 ? routePoints.last : start;
    final isSamePoint = (start.latitude - goal.latitude).abs() < 1e-6 &&
        (start.longitude - goal.longitude).abs() < 1e-6;
    final startPoint =
        isSamePoint ? LatLng(start.latitude + 0.00008, start.longitude) : start;

    markers.add(Marker(
      point: goal,
      width: _markerSize,
      height: _markerSize,
      alignment: Alignment.center,
      child: goalIcon!,
    ));
    markers.add(Marker(
      point: startPoint,
      width: _markerSize,
      height: _markerSize,
      alignment: Alignment.center,
      child: startIcon,
    ));
  }

  return markers;
}

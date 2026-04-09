import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/parsers/gpx_parser.dart';
import '../../domain/models/user_poi.dart';
import '../../utils/map_utils.dart';
import 'marker_icon_service.dart';

/// 距離マーカーを表示するズームレベルの閾値。この値以上で拡大しているときに表示する。
const double distanceMarkerZoomThreshold = 8.0;

/// ルート総距離（メートル）に応じて km 単位のインターバルを決定する。
/// - 総距離 < 110km  → 10km 毎
/// - 110km ≤ 総距離 < 600km → 50km 毎
/// - 600km ≤ 総距離 → 100km 毎
double _resolveKmIntervalMeters(double totalMeters) {
  final totalKm = totalMeters / 1000;
  if (totalKm < 110) return 10000.0;
  if (totalKm < 610) return 50000.0;
  return 100000.0;
}

/// ルート総距離（メートル）に応じて mile 単位のインターバルを決定する。
/// - 総距離 < 80km (≈ 50mi)  → 10mi 毎
/// - 80km ≤ 総距離 < 640km (≈ 400mi) → 50mi 毎
/// - 640km ≤ 総距離 → 100mi 毎
double _resolveMileIntervalMeters(double totalMeters) {
  final totalKm = totalMeters / 1000;
  if (totalKm < 80) return 10 * 1609.344;
  if (totalKm < 640) return 50 * 1609.344;
  return 100 * 1609.344;
}

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
  int distanceUnit = 0,
}) async {
  final showDistanceMarkers =
      zoomLevel != null && zoomLevel >= distanceMarkerZoomThreshold;
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

  // 描画順: 距離マーカー → POI（インフォ→CP）→ ユーザー POI（同上）→ ゴール → スタート（最前面）
  // 同一座標で重なる場合はチェックポイントを手前に（後から add）

  if (routePoints.isNotEmpty && showDistanceMarkers) {
    final totalMeters =
        distanceAlongTrackFromStart(routePoints, routePoints.length - 1);
    final intervalMeters = distanceUnit == 1
        ? _resolveMileIntervalMeters(totalMeters)
        : _resolveKmIntervalMeters(totalMeters);
    final distanceList =
        distanceMarkersAlongTrack(routePoints, intervalMeters: intervalMeters);
    for (var i = 0; i < distanceList.length; i++) {
      final m = distanceList[i];
      final label = distanceUnit == 1
          ? '${(m.distanceKm / 1.609344).round()}mi'
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
    void addGpxPoiMarker(GpxPoi poi) {
      final icon = poi.isControl ? poiIconCheckpoint : poiIconOrange;
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

    for (final poi in pois) {
      if (!poi.isControl) addGpxPoiMarker(poi);
    }
    for (final poi in pois) {
      if (poi.isControl) addGpxPoiMarker(poi);
    }
  }

  if (userPois.isNotEmpty &&
      poiIconOrange != null &&
      poiIconCheckpoint != null) {
    void addUserPoiMarker(UserPoi poi) {
      final icon = poi.isCheckpoint ? poiIconCheckpoint : poiIconOrange;
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

    for (final poi in userPois) {
      if (!poi.isCheckpoint) addUserPoiMarker(poi);
    }
    for (final poi in userPois) {
      if (poi.isCheckpoint) addUserPoiMarker(poi);
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
      child: goalIcon,
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

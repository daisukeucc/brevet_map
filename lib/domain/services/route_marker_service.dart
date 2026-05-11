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
  Widget? poiIconCheckpointPhoto;
  Widget? poiIconStore;
  Widget? poiIconHotel;
  Widget? poiIconDining;
  Widget? poiIconStation;

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
    final hasVisibleGpxPoi = pois.any((p) => !p.isGpxDotType);
    if (hasVisibleGpxPoi || userPois.isNotEmpty) {
      poiIconOrange = await createPoiInfoMarkerIcon();
      poiIconCheckpoint = await createPoiCheckpointMarkerIcon();
      poiIconCheckpointPhoto = await createPoiCheckpointPhotoMarkerIcon();
      poiIconStore = await createPoiStoreMarkerIcon();
      poiIconHotel = await createPoiHotelMarkerIcon();
      poiIconDining = await createPoiDiningMarkerIcon();
      poiIconStation = await createPoiStationMarkerIcon();
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

  if (pois.isNotEmpty &&
      poiIconOrange != null &&
      poiIconCheckpoint != null &&
      poiIconCheckpointPhoto != null) {
    void addGpxPoiMarker(GpxPoi poi) {
      final Widget icon;
      if (!poi.isCheckpoint) {
        icon = poiIconOrange!;
      } else if (poi.isPhotoCheckpointMarker) {
        icon = poiIconCheckpointPhoto!;
      } else {
        icon = poiIconCheckpoint!;
      }
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
      if (poi.isGpxDotType) continue;
      if (!poi.isCheckpoint) addGpxPoiMarker(poi);
    }
    for (final poi in pois) {
      if (poi.isGpxDotType) continue;
      if (poi.isCheckpoint) addGpxPoiMarker(poi);
    }
  }

  if (userPois.isNotEmpty &&
      poiIconOrange != null &&
      poiIconCheckpoint != null &&
      poiIconCheckpointPhoto != null &&
      poiIconStore != null &&
      poiIconHotel != null &&
      poiIconDining != null &&
      poiIconStation != null) {
    void addUserPoiMarker(UserPoi poi) {
      // start/finish は緑・赤マーカーでタップを処理するためスキップ
      final bmType = poi.bmExt?.type;
      if (bmType == 'start' || bmType == 'finish') return;

      final Widget icon;
      switch (poi.poiType) {
        case UserPoiType.checkpoint:
          icon = poiIconCheckpoint!;
          break;
        case UserPoiType.information:
          icon = poiIconOrange!;
          break;
        case UserPoiType.photo:
          icon = poiIconCheckpointPhoto!;
          break;
        case UserPoiType.store:
          icon = poiIconStore!;
          break;
        case UserPoiType.hotel:
          icon = poiIconHotel!;
          break;
        case UserPoiType.dining:
          icon = poiIconDining!;
          break;
        case UserPoiType.station:
          icon = poiIconStation!;
          break;
      }
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

  if (startIcon != null && goalIcon != null) {
    // start/finish UserPoi があればその座標を使い、なければ routePoints の端点にフォールバック
    final startPoi = userPois.cast<UserPoi?>().firstWhere(
      (p) => p?.bmExt?.type == 'start',
      orElse: () => null,
    );
    final finishPoi = userPois.cast<UserPoi?>().firstWhere(
      (p) => p?.bmExt?.type == 'finish',
      orElse: () => null,
    );

    final startPoint = startPoi != null
        ? startPoi.position
        : (routePoints.isNotEmpty ? routePoints.first : null);
    final goalPoint = finishPoi != null
        ? finishPoi.position
        : (routePoints.isNotEmpty ? routePoints.last : null);

    if (startPoint != null && goalPoint != null) {
      final isSamePoint =
          (startPoint.latitude - goalPoint.latitude).abs() < 1e-6 &&
              (startPoint.longitude - goalPoint.longitude).abs() < 1e-6;
      final adjustedStartPoint = isSamePoint
          ? LatLng(startPoint.latitude + 0.00008, startPoint.longitude)
          : startPoint;

      markers.add(Marker(
        point: goalPoint,
        width: _markerSize,
        height: _markerSize,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: finishPoi != null ? () => onUserPoiTap?.call(finishPoi) : null,
          child: goalIcon,
        ),
      ));
      markers.add(Marker(
        point: adjustedStartPoint,
        width: _markerSize,
        height: _markerSize,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: startPoi != null ? () => onUserPoiTap?.call(startPoi) : null,
          child: startIcon,
        ),
      ));
    }
  }

  return markers;
}

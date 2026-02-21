import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 複数の座標を囲む [LatLngBounds] を返す。空のときは null。
LatLngBounds? boundsFromPoints(List<LatLng> points) {
  if (points.isEmpty) return null;
  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLng = points.first.longitude;
  double maxLng = points.first.longitude;
  for (final p in points) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

/// ルート座標とPOI座標を合わせたバウンドを返す。
LatLngBounds? boundsFromPointsWithPois(
    List<LatLng> points, List<LatLng> poiPoints) {
  final all = [...points, ...poiPoints];
  return boundsFromPoints(all);
}

/// 2点間の直線距離をメートルで返す。
double distanceBetweenLatLng(LatLng a, LatLng b) {
  return Geolocator.distanceBetween(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );
}

/// トラック先頭から [toIndex] 番目（0-based）のポイントまで、ルートに沿った累積距離をメートルで返す。
/// [toIndex] が 0 のときは 0。範囲外のときは末端までの距離を返す。
double distanceAlongTrackFromStart(List<LatLng> trackPoints, int toIndex) {
  if (trackPoints.isEmpty) return 0;
  final end = toIndex.clamp(0, trackPoints.length - 1);
  double sum = 0;
  for (var i = 0; i < end; i++) {
    sum += distanceBetweenLatLng(trackPoints[i], trackPoints[i + 1]);
  }
  return sum;
}

/// トラック上で [point] に最も近いポイントを探し、スタートからそのポイントまでのルート沿い距離（メートル）を返す。
/// スタートから「そのポイントに最も近いトラック上の位置」までの走行距離の目安として使える。
double distanceFromStartToPointAlongTrack(
    List<LatLng> trackPoints, LatLng point) {
  if (trackPoints.isEmpty) return 0;
  var bestIndex = 0;
  var bestDist = distanceBetweenLatLng(trackPoints[0], point);
  for (var i = 1; i < trackPoints.length; i++) {
    final d = distanceBetweenLatLng(trackPoints[i], point);
    if (d < bestDist) {
      bestDist = d;
      bestIndex = i;
    }
  }
  return distanceAlongTrackFromStart(trackPoints, bestIndex);
}

/// ルート上で [intervalMeters] 毎（デフォルト 10km）の距離となる位置のリストを返す。
/// 各要素は (距離km, その地点の座標)。地図に「10km」「20km」などのマーカーを打つときに使う。
List<({double distanceKm, LatLng position})> distanceMarkersAlongTrack(
  List<LatLng> trackPoints, {
  double intervalMeters = 10000,
}) {
  final result = <({double distanceKm, LatLng position})>[];
  if (trackPoints.isEmpty || intervalMeters <= 0) return result;

  var nextTargetM = intervalMeters;
  var accumulatedM = 0.0;

  for (var i = 0; i < trackPoints.length - 1; i++) {
    final a = trackPoints[i];
    final b = trackPoints[i + 1];
    final segmentM = distanceBetweenLatLng(a, b);

    while (nextTargetM <= accumulatedM + segmentM && segmentM > 0) {
      final t = (nextTargetM - accumulatedM) / segmentM;
      final lat = a.latitude + t * (b.latitude - a.latitude);
      final lng = a.longitude + t * (b.longitude - a.longitude);
      result.add((
        distanceKm: nextTargetM / 1000,
        position: LatLng(lat, lng),
      ));
      nextTargetM += intervalMeters;
    }
    accumulatedM += segmentM;
  }

  return result;
}

/// 2点間の進行方向を度（0=北、90=東）で返す。移動が短い（3m未満）場合は null。
double? bearingFromPositions(Position from, Position to) {
  final dist = Geolocator.distanceBetween(
    from.latitude,
    from.longitude,
    to.latitude,
    to.longitude,
  );
  if (dist < 3.0) return null;
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLon = (to.longitude - from.longitude) * math.pi / 180;
  final x = math.sin(dLon) * math.cos(lat2);
  final y = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  var bearing = math.atan2(x, y) * 180 / math.pi;
  return (bearing + 360) % 360;
}

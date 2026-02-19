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

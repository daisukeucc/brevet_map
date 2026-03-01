import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'marker_icon_service.dart';

/// ルートを描画し、スタート・ゴールマーカーを更新する。[start] で開始、[cancel] でタイマー解除。
class RouteAnimationRunner {
  Timer? _timer;

  static const _initialPoints = 10;
  static const _interval = Duration(milliseconds: 20);
  static const _pointsPerFrame = 5;

  Future<void> start(
    List<LatLng> fullPoints, {
    required void Function(Set<Polyline>) onPolyline,
    required void Function(Set<Marker>) onMarkers,
    required bool Function() mounted,
    bool animate = true,
    bool buildMarkers = true,
  }) async {
    _timer?.cancel();
    if (fullPoints.isEmpty) return;

    if (buildMarkers) {
      final markers = await _buildStartGoalMarkers(fullPoints, mounted);
      if (markers != null) onMarkers(markers);
    }

    final useAnimation = animate &&
        fullPoints.length > _initialPoints &&
        fullPoints.length <= 500;

    if (!useAnimation) {
      onPolyline({
        Polyline(
          polylineId: const PolylineId('initial_route'),
          points: fullPoints,
          color: Colors.red,
          width: 5,
        ),
      });
      return;
    }

    final startPoints = fullPoints.sublist(0, _initialPoints);
    onPolyline({
      Polyline(
        polylineId: const PolylineId('initial_route'),
        points: startPoints,
        color: Colors.red,
        width: 5,
      ),
    });

    var animatedCount = startPoints.length;
    _timer = Timer.periodic(_interval, (t) {
      if (!mounted() || fullPoints.isEmpty) {
        t.cancel();
        return;
      }
      final nextCount =
          (animatedCount + _pointsPerFrame).clamp(0, fullPoints.length);
      onPolyline({
        Polyline(
          polylineId: const PolylineId('initial_route'),
          points: fullPoints.sublist(0, nextCount),
          color: Colors.red,
          width: 5,
        ),
      });
      animatedCount = nextCount;
      if (nextCount >= fullPoints.length) {
        t.cancel();
        _timer = null;
      }
    });
  }

  Future<Set<Marker>?> _buildStartGoalMarkers(
    List<LatLng> points,
    bool Function() mounted,
  ) async {
    if (points.isEmpty) return null;
    final start = points.first;
    final goal = points.length > 1 ? points.last : start;
    BitmapDescriptor? startIcon;
    BitmapDescriptor? goalIcon;
    try {
      startIcon = await createRoundedSquareMarkerIcon(
        backgroundColor: Colors.green,
        isPlayIcon: true,
      );
      goalIcon = await createRoundedSquareMarkerIcon(
        backgroundColor: Colors.red,
        isPlayIcon: false,
      );
    } catch (_) {
      return null;
    }
    if (!mounted()) return null;
    final isSamePoint = (start.latitude - goal.latitude).abs() < 1e-6 &&
        (start.longitude - goal.longitude).abs() < 1e-6;
    final startAnchor =
        isSamePoint ? const Offset(0, 0) : const Offset(0.5, 0.5);
    return {
      Marker(
        markerId: const MarkerId('start'),
        position: start,
        icon: startIcon,
        anchor: startAnchor,
        zIndex: 1,
      ),
      Marker(
        markerId: const MarkerId('goal'),
        position: goal,
        icon: goalIcon,
        anchor: const Offset(0.5, 0.5),
        zIndex: 0,
      ),
    };
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

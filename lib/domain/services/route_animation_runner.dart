import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'marker_icon_service.dart';

/// ルートを描画し、スタート・ゴールマーカーを更新する。[start] で開始、[cancel] でタイマー解除。
class RouteAnimationRunner {
  Timer? _timer;

  static const _initialPoints = 10;
  static const _interval = Duration(milliseconds: 20);
  static const _pointsPerFrame = 5;

  static const double _markerSize = 72.0;

  Future<void> start(
    List<LatLng> fullPoints, {
    required void Function(List<Polyline>) onPolyline,
    required void Function(List<Marker>) onMarkers,
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
      onPolyline([
        Polyline(
          points: fullPoints,
          color: Colors.red,
          strokeWidth: 5,
        ),
      ]);
      return;
    }

    final startPoints = fullPoints.sublist(0, _initialPoints);
    onPolyline([
      Polyline(
        points: startPoints,
        color: Colors.red,
        strokeWidth: 5,
      ),
    ]);

    var animatedCount = startPoints.length;
    _timer = Timer.periodic(_interval, (t) {
      if (!mounted() || fullPoints.isEmpty) {
        t.cancel();
        return;
      }
      final nextCount =
          (animatedCount + _pointsPerFrame).clamp(0, fullPoints.length);
      onPolyline([
        Polyline(
          points: fullPoints.sublist(0, nextCount),
          color: Colors.red,
          strokeWidth: 5,
        ),
      ]);
      animatedCount = nextCount;
      if (nextCount >= fullPoints.length) {
        t.cancel();
        _timer = null;
      }
    });
  }

  Future<List<Marker>?> _buildStartGoalMarkers(
    List<LatLng> points,
    bool Function() mounted,
  ) async {
    if (points.isEmpty) return null;
    final start = points.first;
    final goal = points.length > 1 ? points.last : start;
    Widget? startIcon;
    Widget? goalIcon;
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
    final startPoint = isSamePoint
        ? LatLng(start.latitude + 0.00008, start.longitude)
        : start;
    // スタートを上に表示するため、ゴールを先に追加してスタートを後に描画
    return [
      Marker(
        point: goal,
        width: _markerSize,
        height: _markerSize,
        alignment: Alignment.center,
        child: goalIcon!,
      ),
      Marker(
        point: startPoint,
        width: _markerSize,
        height: _markerSize,
        alignment: Alignment.center,
        child: startIcon!,
      ),
    ];
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

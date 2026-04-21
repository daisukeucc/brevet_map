import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

const double kmPerMile = 1.609344;

/// [value] を小数第1位で丸め、`.0` で終わるときは整数表示にする（例: 20.0→20、20.5→20.5）。
String _formatDistanceDisplayValue(double value) {
  final s = value.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// 距離を単位に応じてフォーマット（0=km, 1=mile）。小数点以下第1位まで（表示用に丸め）。
String formatDistance(double km, int unit) {
  if (unit == 1) {
    final mi = km / kmPerMile;
    return '${_formatDistanceDisplayValue(mi)}mi';
  }
  return '${_formatDistanceDisplayValue(km)}km';
}

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
    LatLng(minLat, minLng),
    LatLng(maxLat, maxLng),
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

/// トラック上で [point] に最も近いポイントのインデックスを返す。
int nearestTrackIndex(List<LatLng> trackPoints, LatLng point) {
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
  return bestIndex;
}

/// [fromIndex] から [toIndex] の区間の獲得標高をメートルで返す。
/// [threshold] 未満の上昇はノイズとして無視する（デフォルト 8m）。
double elevationGainBetweenIndices(
    List<double?> elevations, int fromIndex, int toIndex,
    {double threshold = 4.0}) {
  if (elevations.isEmpty) return 0;
  final start = fromIndex.clamp(0, elevations.length - 1);
  final end = toIndex.clamp(0, elevations.length - 1);
  if (start >= end) return 0;
  double gain = 0;
  double? ref;
  for (var i = start; i <= end; i++) {
    final ele = elevations[i];
    if (ele == null) continue;
    if (ref == null) {
      ref = ele;
      continue;
    }
    final diff = ele - ref;
    if (diff >= threshold) {
      gain += diff;
      ref = ele;
    } else if (diff <= -threshold) {
      ref = ele;
    }
  }
  return gain;
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

/// 往復ルートにおける往路/復路の区間
enum RouteLeg { outbound, returnRoute, ambiguous }

/// ルート区間判定付きの距離結果
typedef RouteLegResult = ({
  double alongTrackM,
  double toRouteM,
  RouteLeg leg,
});

/// 往復ルートで現在地が往路か復路かを bearing で判定する。
/// [previousPosition] があればスタート/ゴール同一地点での区別が可能。
/// 折り返し点付近（全長の45〜55%）は往路に含める。
RouteLegResult getRouteLegWithBearing(
  List<LatLng> trackPoints,
  LatLng currentPosition, {
  LatLng? previousPosition,
}) {
  if (trackPoints.isEmpty) {
    return (alongTrackM: 0, toRouteM: double.infinity, leg: RouteLeg.ambiguous);
  }
  final totalM =
      distanceAlongTrackFromStart(trackPoints, trackPoints.length - 1);
  if (totalM <= 0) {
    return (alongTrackM: 0, toRouteM: double.infinity, leg: RouteLeg.ambiguous);
  }

  const candidateEpsilonM = 50.0;
  final candidates = <({int index, double dist, double alongM})>[];
  var minDist = double.infinity;
  for (var i = 0; i < trackPoints.length; i++) {
    final d = distanceBetweenLatLng(trackPoints[i], currentPosition);
    if (d < minDist) minDist = d;
  }
  for (var i = 0; i < trackPoints.length; i++) {
    final d = distanceBetweenLatLng(trackPoints[i], currentPosition);
    if (d <= minDist + candidateEpsilonM) {
      candidates.add((
        index: i,
        dist: d,
        alongM: distanceAlongTrackFromStart(trackPoints, i),
      ));
    }
  }
  if (candidates.isEmpty) {
    return (alongTrackM: 0, toRouteM: minDist, leg: RouteLeg.ambiguous);
  }

  int bestIndex;
  double bestAlongM;
  if (candidates.length == 1) {
    bestIndex = candidates[0].index;
    bestAlongM = candidates[0].alongM;
  } else if (candidates.isNotEmpty && previousPosition != null) {
    final userBearing = bearingBetweenLatLng(previousPosition, currentPosition);
    bestIndex = candidates[0].index;
    bestAlongM = candidates[0].alongM;
    if (userBearing != null) {
      var bestDiff = 180.0;
      for (final c in candidates) {
        double? routeBearing;
        if (c.index == 0 && trackPoints.length > 1) {
          routeBearing = bearingBetweenLatLng(
            trackPoints[0],
            trackPoints[1],
          );
        } else if (c.index == trackPoints.length - 1 && trackPoints.length > 1) {
          routeBearing = bearingBetweenLatLng(
            trackPoints[trackPoints.length - 2],
            trackPoints[trackPoints.length - 1],
          );
        } else if (c.index > 0 && c.index < trackPoints.length - 1) {
          routeBearing = bearingBetweenLatLng(
            trackPoints[c.index - 1],
            trackPoints[c.index],
          );
        }
        if (routeBearing == null) continue;
        var diff = (userBearing - routeBearing).abs();
        if (diff > 180) diff = 360 - diff;
        if (diff < bestDiff) {
          bestDiff = diff;
          bestIndex = c.index;
          bestAlongM = c.alongM;
        }
      }
    }
  } else {
    bestIndex = candidates[0].index;
    bestAlongM = candidates[0].alongM;
  }

  final toRouteM = distanceBetweenLatLng(trackPoints[bestIndex], currentPosition);
  final ratio = bestAlongM / totalM;
  final leg = ratio < 0.55 ? RouteLeg.outbound : RouteLeg.returnRoute;
  return (alongTrackM: bestAlongM, toRouteM: toRouteM, leg: leg);
}

/// ルート上に最も近い点までの距離（メートル）と、スタートからその点までのルート沿い距離（メートル）を返す。
/// [withinDistanceM] 未満なら (距離沿い, ルートまでの距離)、以上なら (0, ルートまでの距離)。
({double alongTrackM, double toRouteM}) distanceToRouteWithAlongTrack(
    List<LatLng> trackPoints, LatLng point) {
  if (trackPoints.isEmpty) return (alongTrackM: 0, toRouteM: double.infinity);
  var bestIndex = 0;
  var bestDist = distanceBetweenLatLng(trackPoints[0], point);
  for (var i = 1; i < trackPoints.length; i++) {
    final d = distanceBetweenLatLng(trackPoints[i], point);
    if (d < bestDist) {
      bestDist = d;
      bestIndex = i;
    }
  }
  return (
    alongTrackM: distanceAlongTrackFromStart(trackPoints, bestIndex),
    toRouteM: bestDist,
  );
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

/// ルート上の [targetKm] km 地点の座標を線形補間で返す。
/// ルートが空・負値のときは null。[targetKm] がルート全長を超えた場合は末端を返す。
LatLng? coordAtKm(List<LatLng> trackPoints, double targetKm) {
  if (trackPoints.isEmpty || targetKm < 0) return null;
  if (trackPoints.length == 1) return trackPoints.first;
  final targetM = targetKm * 1000;
  var accumulated = 0.0;
  for (var i = 0; i < trackPoints.length - 1; i++) {
    final a = trackPoints[i];
    final b = trackPoints[i + 1];
    final segmentM = distanceBetweenLatLng(a, b);
    if (accumulated + segmentM >= targetM) {
      if (segmentM == 0) return a;
      final t = (targetM - accumulated) / segmentM;
      return LatLng(
        a.latitude + t * (b.latitude - a.latitude),
        a.longitude + t * (b.longitude - a.longitude),
      );
    }
    accumulated += segmentM;
  }
  return trackPoints.last;
}

/// ルートの種類
enum RouteType {
  /// 往復（同じ道を行って戻る）
  outAndBack,

  /// 周遊（ループして戻る）
  loop,

  /// 地点間（スタートとゴールが異なる）
  pointToPoint,
}

/// ルートが往復・周遊・地点間のどれかを判定する。
///
/// 判定手順:
/// 1. スタート〜ゴール間の距離が総距離の15%超かつ3km超 → 地点間
/// 2. 前半と後半の重複率が30%超 → 往復（「ほぼ往復」も含む）
/// 3. それ以外 → 周遊
RouteType detectRouteType(List<LatLng> points) {
  if (points.length < 10) return RouteType.pointToPoint;

  // 累積距離を事前計算（O(n)、以降の計算で再利用）
  final cumDist = List<double>.filled(points.length, 0);
  for (var i = 1; i < points.length; i++) {
    cumDist[i] = cumDist[i - 1] + distanceBetweenLatLng(points[i - 1], points[i]);
  }
  final totalDist = cumDist.last;
  if (totalDist == 0) return RouteType.pointToPoint;

  final startEndDist = distanceBetweenLatLng(points.first, points.last);
  final startEndThreshold = math.max(totalDist * 0.15, 3000);
  if (startEndDist > startEndThreshold) {
    return RouteType.pointToPoint;
  }

  // ルートの自己重複を検出して往復判定する。
  // 折り返し位置や回数に依存せず、ルート上の任意の点が
  // 「ルート距離で100km以上離れた他の地点と500m以内に近接するか」を検査する。
  // 往復なら往路の点と復路の点が近接するため自己重複率が高くなる。
  const nSamples = 40;
  const overlapThresholdM = 1500.0;
  // 近すぎる区間同士の誤マッチを防ぐ最小ルート距離差。
  // 短いルートでも機能するよう総距離の20%（最低2km）を使用する。
  final minRouteSeparationM = math.max(totalDist * 0.2, 2000.0);

  // 二分探索で目標距離に最も近いインデックスを返す
  int indexAtDist(double target) {
    var lo = 0;
    var hi = points.length - 1;
    while (lo < hi) {
      final m = (lo + hi) ~/ 2;
      if (cumDist[m] < target) {
        lo = m + 1;
      } else {
        hi = m;
      }
    }
    return lo;
  }

  final sampleInterval = totalDist / (nSamples + 1);
  final samples = <({double routeDist, LatLng pos})>[];
  for (var s = 1; s <= nSamples; s++) {
    final d = s * sampleInterval;
    samples.add((routeDist: d, pos: points[indexAtDist(d)]));
  }

  var selfMatchCount = 0;
  for (var i = 0; i < samples.length; i++) {
    final a = samples[i];
    for (var j = 0; j < samples.length; j++) {
      if (i == j) continue;
      final b = samples[j];
      if ((a.routeDist - b.routeDist).abs() < minRouteSeparationM) continue;
      if (distanceBetweenLatLng(a.pos, b.pos) < overlapThresholdM) {
        selfMatchCount++;
        break;
      }
    }
  }

  final overlapRatio = selfMatchCount / nSamples;
  return overlapRatio > 0.3 ? RouteType.outAndBack : RouteType.loop;
}

/// ルートタイプと折り返しインデックスをまとめて返す。
/// [compute] でバックグラウンド実行できるようトップレベル関数として定義。
({RouteType type, int turnaroundIdx}) analyzeRoute(List<LatLng> points) {
  final routeType = detectRouteType(points);
  final turnaroundIdx = routeType == RouteType.outAndBack
      ? findTurnaroundIndex(points)
      : points.length;
  return (type: routeType, turnaroundIdx: turnaroundIdx);
}

/// 往復ルートの折り返し点インデックスを返す（累積距離が総距離の半分を超えた最初のインデックス）。
int findTurnaroundIndex(List<LatLng> points) {
  if (points.length < 2) return 0;
  final totalDist = distanceAlongTrackFromStart(points, points.length - 1);
  final halfDist = totalDist / 2;
  var accumulated = 0.0;
  for (var i = 0; i < points.length - 1; i++) {
    final d = distanceBetweenLatLng(points[i], points[i + 1]);
    if (accumulated + d >= halfDist) return i + 1;
    accumulated += d;
  }
  return points.length ~/ 2;
}

/// 2点間の進行方向を度（0=北、90=東）で返す。移動が短い（3m未満）場合は null。
double? bearingBetweenLatLng(LatLng from, LatLng to) {
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

/// 2点間の進行方向を度（0=北、90=東）で返す。移動が短い（3m未満）の場合は null。
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

/// 2つの角度の符号付き差分を -180〜+180 で返す（0/360境界を跨いでも正しく動作）
double angleDiff(double from, double to) {
  return ((to - from + 540) % 360) - 180;
}

/// 角度のローパスフィルター（0/360境界を跨いでも正しく動作）
/// [alpha] が大きいほど滑らか（反応が遅い）。0.0〜1.0 の範囲で指定。
double applyAngleLowPass(double prev, double next, double alpha) {
  final diff = angleDiff(prev, next);
  return (prev + diff * (1 - alpha) + 360) % 360;
}

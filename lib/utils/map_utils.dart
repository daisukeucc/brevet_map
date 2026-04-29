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

/// [formatDistance] の数値部分のみ（単位なし）。ルート表示と同じ丸め規則。
String formatDistanceNumeric(double km, int unit) {
  if (unit == 1) {
    return _formatDistanceDisplayValue(km / kmPerMile);
  }
  return _formatDistanceDisplayValue(km);
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

/// [fromIndex] と [toIndex] の間をルートに沿って進んだときの距離（メートル）。
/// 両端の頂点を含む。[fromIndex] > [toIndex] のときはインデックスを入れ替えて計算する。
double distanceAlongTrackBetweenIndices(
    List<LatLng> trackPoints, int fromIndex, int toIndex) {
  if (trackPoints.length < 2) return 0;
  var lo = fromIndex.clamp(0, trackPoints.length - 1);
  var hi = toIndex.clamp(0, trackPoints.length - 1);
  if (lo > hi) {
    final t = lo;
    lo = hi;
    hi = t;
  }
  double sum = 0;
  for (var i = lo; i < hi; i++) {
    sum += distanceBetweenLatLng(trackPoints[i], trackPoints[i + 1]);
  }
  return sum;
}

/// POI 詳細シートの「区間標高グラフ」用。単位 km / m。
class ElevationSegmentChartData {
  const ElevationSegmentChartData({
    required this.segmentKm,
    required this.segmentElevationGainM,
    required this.kmAlongRouteStart,
    required this.kmAlongRouteEnd,
    required this.kmFromSegmentStart,
    required this.elevationMeters,
  });

  /// ルート上で「前 POI（またはスタート）〜この POI」の長さ（km）。
  final double segmentKm;

  /// 同一区間の獲得標高（メートル）。トラック上の索引は [buildElevationSegmentChartData] 内の lo〜hi。
  final double segmentElevationGainM;

  /// トラック先頭から区間始点（直前 POI に対応するトラック頂点）までの沿線距離（km）。
  final double kmAlongRouteStart;

  /// トラック先頭から区間終点（この POI に対応するトラック頂点）までの沿線距離（km）。
  final double kmAlongRouteEnd;

  /// 区間開始からの累積距離（km）。[elevationMeters] と同じ長さ。
  final List<double> kmFromSegmentStart;

  /// 各サンプル点の標高（m）。欠損は前方埋め後の値。
  final List<double> elevationMeters;

  bool get hasElevation => elevationMeters.any((e) => e.isFinite);
}

/// 「直前の POI（またはスタート）からこの POI」までのルート区間の距離・標高サンプルを構築する。
/// [poiIndex] が 0 のときは **トラック全体**（スタート〜終点）を対象とし、それ以外は前地点から当該 POI までの区間のみとする。
/// [elevations] がトラックと不一致または空のときは標高は前方埋めのみ試み、無ければ NaN を詰める。
ElevationSegmentChartData? buildElevationSegmentChartData({
  required List<LatLng> trackPoints,
  required List<double?> elevations,
  required List<LatLng> poiPositions,
  required int poiIndex,
  int maxSamples = 450,
}) {
  if (trackPoints.isEmpty || poiPositions.isEmpty) return null;
  if (poiIndex < 0 || poiIndex >= poiPositions.length) return null;

  final alignedElev = elevations.length == trackPoints.length
      ? elevations
      : List<double?>.filled(trackPoints.length, null);

  // 最終 POI（ゴール）は地理的近傍でなくトラック末尾を使う（折り返しルートで近傍が先頭付近になる誤りを防ぐ）
  final toIdx = poiIndex == poiPositions.length - 1
      ? trackPoints.length - 1
      : nearestTrackIndex(trackPoints, poiPositions[poiIndex]);
  final fromIdx = poiIndex == 0
      ? 0
      : nearestTrackIndex(trackPoints, poiPositions[poiIndex - 1]);

  var lo = fromIdx;
  var hi = toIdx;
  if (lo > hi) {
    final t = lo;
    lo = hi;
    hi = t;
  }

  /// スタート地点（先頭 POI）の詳細では、区間ではなくルート全体の標高プロファイルを表示する。
  if (poiIndex == 0) {
    lo = 0;
    hi = trackPoints.length - 1;
  }

  final segmentM = distanceAlongTrackBetweenIndices(trackPoints, lo, hi);
  final segmentKm = segmentM / 1000.0;
  final segmentElevationGainM =
      elevationGainBetweenIndices(alignedElev, lo, hi);

  final kmAlongRouteStart =
      distanceAlongTrackFromStart(trackPoints, lo) / 1000.0;
  final kmAlongRouteEnd =
      distanceAlongTrackFromStart(trackPoints, hi) / 1000.0;

  final kmRaw = <double>[];
  final eleNullable = <double?>[];

  double cumKm = 0;
  for (var i = lo; i <= hi; i++) {
    if (i > lo) {
      cumKm += distanceBetweenLatLng(trackPoints[i - 1], trackPoints[i]) /
          1000.0;
    }
    kmRaw.add(cumKm);
    eleNullable.add(i < alignedElev.length ? alignedElev[i] : null);
  }

  double? last;
  for (var i = 0; i < eleNullable.length; i++) {
    final e = eleNullable[i];
    if (e != null && e.isFinite) {
      last = e;
    } else if (last != null) {
      eleNullable[i] = last;
    }
  }
  last = null;
  for (var i = eleNullable.length - 1; i >= 0; i--) {
    final e = eleNullable[i];
    if (e != null && e.isFinite) {
      last = e;
    } else if (last != null) {
      eleNullable[i] = last;
    }
  }

  final elevFilled = <double>[];
  for (final e in eleNullable) {
    elevFilled.add((e != null && e.isFinite) ? e : double.nan);
  }

  final kmDown = <double>[];
  final eleDown = <double>[];
  if (kmRaw.length <= maxSamples) {
    kmDown.addAll(kmRaw);
    eleDown.addAll(elevFilled);
  } else {
    final step = kmRaw.length / maxSamples;
    for (var i = 0; i < maxSamples; i++) {
      final j = (i * step).floor().clamp(0, kmRaw.length - 1);
      kmDown.add(kmRaw[j]);
      eleDown.add(elevFilled[j]);
    }
  }

  return ElevationSegmentChartData(
    segmentKm: segmentKm,
    segmentElevationGainM: segmentElevationGainM,
    kmAlongRouteStart: kmAlongRouteStart,
    kmAlongRouteEnd: kmAlongRouteEnd,
    kmFromSegmentStart: kmDown,
    elevationMeters: eleDown,
  );
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

// ── isolate 用（compute()）──────────────────────────────────────────────────

/// compute() に渡す入力型。
typedef PoiElevationGainInput = ({
  List<LatLng> trackPoints,
  List<double?> elevations,
  List<LatLng> poiPositions,
});

/// Haversine 式による2点間距離（メートル）。
/// isolate 内では Geolocator（プラットフォームチャネル）が使えないため純粋 Dart で実装。
double _haversineMeters(LatLng a, LatLng b) {
  const r = 6371000.0;
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final dLat = (b.latitude - a.latitude) * math.pi / 180;
  final dLon = (b.longitude - a.longitude) * math.pi / 180;
  final sinA = math.sin(dLat / 2);
  final sinB = math.sin(dLon / 2);
  final h = sinA * sinA + math.cos(lat1) * math.cos(lat2) * sinB * sinB;
  return r * 2 * math.asin(math.sqrt(h));
}

int _nearestTrackIndexIsolate(List<LatLng> trackPoints, LatLng point) {
  if (trackPoints.isEmpty) return 0;
  var bestIndex = 0;
  var bestDist = _haversineMeters(trackPoints[0], point);
  for (var i = 1; i < trackPoints.length; i++) {
    final d = _haversineMeters(trackPoints[i], point);
    if (d < bestDist) {
      bestDist = d;
      bestIndex = i;
    }
  }
  return bestIndex;
}

/// compute() で実行する獲得標高計算。
/// 各 POI の「前 POI（またはスタート）→ この POI」区間の獲得標高を返す。
List<double?> computePoiElevationGains(PoiElevationGainInput input) {
  final trackPoints = input.trackPoints;
  final elevations = input.elevations;
  final poiPositions = input.poiPositions;
  if (trackPoints.isEmpty || elevations.isEmpty) {
    return List.filled(poiPositions.length, null);
  }
  final indices = [
    for (var i = 0; i < poiPositions.length; i++)
      // 最終 POI（ゴール）は地理的近傍でなくトラック末尾を使う（折り返しルートで近傍が先頭付近になる誤りを防ぐ）
      i == poiPositions.length - 1
          ? trackPoints.length - 1
          : _nearestTrackIndexIsolate(trackPoints, poiPositions[i]),
  ];
  return [
    for (var i = 0; i < poiPositions.length; i++)
      elevationGainBetweenIndices(
          elevations, i > 0 ? indices[i - 1] : 0, indices[i]),
  ];
}

// ── ここまで isolate 用 ─────────────────────────────────────────────────────

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
        } else if (c.index == trackPoints.length - 1 &&
            trackPoints.length > 1) {
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

  final toRouteM =
      distanceBetweenLatLng(trackPoints[bestIndex], currentPosition);
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
    cumDist[i] =
        cumDist[i - 1] + distanceBetweenLatLng(points[i - 1], points[i]);
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

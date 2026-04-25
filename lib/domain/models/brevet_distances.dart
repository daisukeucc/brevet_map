/// ブルベ公認距離と制限時間のテーブル。
const brevetDistanceTable = [
  (km: 200.0, limitHours: 13.5),
  (km: 300.0, limitHours: 20.0),
  (km: 400.0, limitHours: 27.0),
  (km: 600.0, limitHours: 40.0),
  (km: 1000.0, limitHours: 75.0),
  (km: 1200.0, limitHours: 90.0),
];

/// ルート全長がこれ未満（km）のとき、GPX インポートで finish の `close` を制限時間から付与しない。
const kMinRouteKmForFinishClose = 200.0;

/// ルート距離 [routeKm] に最も近いブルベ距離クラスを返す。
/// テーブル最大距離（1200km）を超える場合は `(km: 0, limitHours: 0)` を返す。
({double km, double limitHours}) matchBrevetDistance(double routeKm) {
  const maxKm = 1200.0;
  if (routeKm > maxKm) return (km: 0, limitHours: 0);

  var best = brevetDistanceTable.first;
  var bestDiff = (routeKm - best.km).abs();
  for (final entry in brevetDistanceTable) {
    final diff = (routeKm - entry.km).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      best = entry;
    }
  }
  return best;
}

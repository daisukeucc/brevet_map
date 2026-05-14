/// ブルベ公認距離と制限時間のテーブル。
///
/// [axisTickStepHours] は POI シート経過時間チャートの横軸目盛り間隔（時間）。
const brevetDistanceTable = [
  (km: 200.0, limitHours: 13.5, axisTickStepHours: 1.0),
  (km: 300.0, limitHours: 20.0, axisTickStepHours: 2.0),
  (km: 400.0, limitHours: 27.0, axisTickStepHours: 5.0),
  (km: 600.0, limitHours: 40.0, axisTickStepHours: 5.0),
  (km: 1000.0, limitHours: 75.0, axisTickStepHours: 10.0),
  (km: 1200.0, limitHours: 90.0, axisTickStepHours: 10.0),
  (km: 1500.0, limitHours: 250.0, axisTickStepHours: 50.0),
];

/// ルート全長がこれ未満（km）のとき、GPX インポートで finish の `close` を制限時間から付与しない。
const kMinRouteKmForFinishClose = 200.0;

/// ルート距離 [routeKm] に最も近いブルベ距離クラスを返す。
///
/// [routeKm] がテーブル最大 [km] を超える場合は、**最終行**（最長公認距離）を返す。
/// 超過分も同一クラス扱いにし、制限時間 0 でメタが保存されチャートが出ないのを防ぐ。
({double km, double limitHours, double axisTickStepHours}) matchBrevetDistance(
  double routeKm,
) {
  if (!routeKm.isFinite || routeKm < 0) {
    return (km: 0, limitHours: 0, axisTickStepHours: 5.0);
  }

  final last = brevetDistanceTable.last;
  final capKm = last.km;
  if (routeKm > capKm) {
    return (
      km: last.km,
      limitHours: last.limitHours,
      axisTickStepHours: last.axisTickStepHours,
    );
  }

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

/// POI 経過時間チャートの横軸目盛り間隔（時間）。
///
/// ルート全長が分かるときは [matchBrevetDistance] の [axisTickStepHours]。
/// ルート未取得などであれば [timeLimitHours] がテーブルのどの行に近いかで決める。
double brevetTimeChartAxisTickStepHours(
  double timeLimitHours, {
  double? routeKm,
}) {
  if (routeKm != null && routeKm > 0 && routeKm.isFinite) {
    final m = matchBrevetDistance(routeKm);
    if (m.km > 0) return m.axisTickStepHours;
  }

  if (!timeLimitHours.isFinite || timeLimitHours <= 0) return 5.0;

  var best = brevetDistanceTable.first;
  var bestDiff = (timeLimitHours - best.limitHours).abs();
  for (final entry in brevetDistanceTable) {
    final d = (timeLimitHours - entry.limitHours).abs();
    if (d < bestDiff) {
      bestDiff = d;
      best = entry;
    }
  }
  return best.axisTickStepHours;
}

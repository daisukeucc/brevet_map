import 'package:shared_preferences/shared_preferences.dart';

const _keyInitialRouteShown = 'initial_route_shown';
const _keySavedRoutePolyline = 'saved_route_polyline';
const _keyGpxPois = 'gpx_pois';
const _keyMapStyleMode = 'map_style_mode';
const _keyLocationStreamActive = 'location_stream_active';
const _keySleepDuration = 'sleep_duration';
const _keyDistanceUnit = 'distance_unit'; // 0=km, 1=mile

/// 初回起動（インストール後初回のみ）かどうかを返す
Future<bool> isFirstLaunch() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_keyInitialRouteShown) ?? false);
}

/// 初回ルート表示済みとしてマークし、以降は Directions API を呼ばないようにする
Future<void> markInitialRouteShown() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyInitialRouteShown, true);
}

/// 初回起動で取得したルートのエンコード済みポリラインを保存する
Future<void> saveRouteEncoded(String encoded) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keySavedRoutePolyline, encoded);
}

/// 保存済みルートのエンコード済みポリラインを返す。未保存なら null
Future<String?> loadRouteEncoded() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keySavedRoutePolyline);
}

/// 既存の保存ルートとGPX POIを削除する（GPXインポート時に上書きするため）
Future<void> clearSavedRoute() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keySavedRoutePolyline);
  await prefs.remove(_keyGpxPois);
}

/// GPXのPOI（ウェイポイント）一覧をJSONで保存する
Future<void> saveGpxPois(String poisJson) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyGpxPois, poisJson);
}

/// 保存済みGPX POIのJSONを返す。未保存なら null
Future<String?> loadGpxPois() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keyGpxPois);
}

/// 地図表示モード（0=通常, 2=ダーク）を保存する
Future<void> saveMapStyleMode(int mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_keyMapStyleMode, mode == 1 ? 2 : mode);
}

/// 保存済みの地図表示モードを返す
Future<int> loadMapStyleMode() async {
  final prefs = await SharedPreferences.getInstance();
  final mode = prefs.getInt(_keyMapStyleMode) ?? 0;
  return mode == 1 ? 2 : mode;
}

/// 位置情報ストリームをONにしたいか（ボタンでONにしたとき true、OFFにしたとき false を保存）
Future<void> saveLocationStreamActive(bool active) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyLocationStreamActive, active);
}

/// 保存済みの位置情報ストリームON/OFFを返す。未保存なら false（OFF）
Future<bool> loadLocationStreamActive() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyLocationStreamActive) ?? false;
}

/// 画面スリープ設定（分）を保存する。0=OFF
Future<void> saveSleepDuration(int minutes) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_keySleepDuration, minutes);
}

/// 保存済みの画面スリープ設定を返す。未保存なら 0（OFF）
Future<int> loadSleepDuration() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_keySleepDuration) ?? 0;
}

/// 距離単位を保存。0=km, 1=mile
Future<void> saveDistanceUnit(int unit) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_keyDistanceUnit, unit);
}

/// 保存済みの距離単位を返す。未保存なら 0（km）
Future<int> loadDistanceUnit() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_keyDistanceUnit) ?? 0;
}

import 'package:shared_preferences/shared_preferences.dart';

const _keyInitialRouteShown = 'initial_route_shown';
const _keySavedRoutePolyline = 'saved_route_polyline';
const _keyGpxPois = 'gpx_pois';
const _keyMapStyleMode = 'map_style_mode';
const _keyLocationStreamActive = 'location_stream_active';

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

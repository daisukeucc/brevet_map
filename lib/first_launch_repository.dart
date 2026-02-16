import 'package:shared_preferences/shared_preferences.dart';

const _keyInitialRouteShown = 'initial_route_shown';
const _keySavedRoutePolyline = 'saved_route_polyline';
const _keyMapStyleMode = 'map_style_mode';

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

/// 地図表示モード（0=通常, 1=モノクロ, 2=ダーク）を保存する
Future<void> saveMapStyleMode(int mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_keyMapStyleMode, mode);
}

/// 保存済みの地図表示モードを返す。未保存なら 0（通常カラー）
Future<int> loadMapStyleMode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_keyMapStyleMode) ?? 0;
}

import 'package:shared_preferences/shared_preferences.dart';

const _keyInitialRouteShown = 'initial_route_shown';
const _keySavedRoutePolyline = 'saved_route_polyline';

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

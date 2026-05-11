import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/bm_extension.dart';

const _keyBrevetMeta = 'brevet_meta';
const _keyDefaultMapLat = 'default_map_lat';
const _keyDefaultMapLng = 'default_map_lng';

const _keyInitialRouteShown = 'initial_route_shown';
const _keySavedRoutePolyline = 'saved_route_polyline';
const _keySavedRouteElevations = 'saved_route_elevations';
const _keyGpxPois = 'gpx_pois';
/// `<type>Dot</type>` の wpt のみ（表示・編集対象外、GPX エクスポートで復元）
const _keyGpxDotWaypoints = 'gpx_dot_waypoints';
/// 最後にインポートした GPX のファイル名ベース（拡張子 `.gpx` 除く、表示・エクスポート既定名用）
const _keyGpxImportBasename = 'gpx_import_basename';
const _keyMapStyleMode = 'map_style_mode';
const _keyLocationStreamActive = 'location_stream_active';
const _keyScreenSleep = 'screen_sleep';
const _keyDistanceUnit = 'distance_unit'; // 0=km, 1=mile
const _keySleepInfoDismissed = 'sleep_info_dismissed';
const _keyLocale = 'locale'; // '' = システム設定に従う、それ以外は言語コード
const _keyBatteryDisplay = 'battery_display'; // true=表示, false=非表示
const _keyLastShownReleaseNoteId =
    'last_shown_release_note_id'; // 例: 1.1.0+18。一度表示した版は再表示しない

/// フォールバック用の既定座標を保存する（表示ルートのスタートなど）
Future<void> saveDefaultMapCoordinates(double lat, double lng) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_keyDefaultMapLat, lat);
  await prefs.setDouble(_keyDefaultMapLng, lng);
}

/// 保存済みの既定座標。未保存なら null
Future<({double lat, double lng})?> loadDefaultMapCoordinatesOptional() async {
  final prefs = await SharedPreferences.getInstance();
  final lat = prefs.getDouble(_keyDefaultMapLat);
  final lng = prefs.getDouble(_keyDefaultMapLng);
  if (lat == null || lng == null) return null;
  return (lat: lat, lng: lng);
}

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

/// GPX インポート時の各 trkpt の標高（デコード後のポイント列と同じ長さ）。少なくとも1点に `<ele>` があるときだけ保存する
Future<void> saveTrackElevations(List<double?> elevations) async {
  final prefs = await SharedPreferences.getInstance();
  if (elevations.isEmpty || !elevations.any((e) => e != null)) {
    await prefs.remove(_keySavedRouteElevations);
    return;
  }
  await prefs.setString(_keySavedRouteElevations, jsonEncode(elevations));
}

/// 保存済みの標高リスト。未保存または無効なら null
Future<List<double?>?> loadTrackElevations() async {
  final prefs = await SharedPreferences.getInstance();
  final s = prefs.getString(_keySavedRouteElevations);
  if (s == null || s.isEmpty) return null;
  try {
    final list = jsonDecode(s) as List<dynamic>;
    return list
        .map((e) => e == null ? null : (e as num).toDouble())
        .toList();
  } catch (_) {
    return null;
  }
}

/// Directions API 等でルートだけ差し替えたとき、GPX の標高キャッシュを消す
Future<void> clearTrackElevations() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keySavedRouteElevations);
}

/// 既存の保存ルートとGPX POIを削除する（GPXインポート時に上書きするため）
Future<void> clearSavedRoute() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keySavedRoutePolyline);
  await prefs.remove(_keySavedRouteElevations);
  await prefs.remove(_keyGpxPois);
  await prefs.remove(_keyGpxDotWaypoints);
  await prefs.remove(_keyGpxImportBasename);
  await prefs.remove(_keyBrevetMeta);
}

/// ブルベメタデータ（距離・スタート時刻・制限時間）を保存する
Future<void> saveBrevetMeta(BmBrevetMeta meta) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyBrevetMeta, jsonEncode(meta.toJson()));
}

/// 保存済みのブルベメタデータを返す。未保存なら null
Future<BmBrevetMeta?> loadBrevetMeta() async {
  final prefs = await SharedPreferences.getInstance();
  final s = prefs.getString(_keyBrevetMeta);
  if (s == null || s.isEmpty) return null;
  try {
    return BmBrevetMeta.fromJson(jsonDecode(s) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

/// Dot ウェイポイント一覧の JSON を保存する
Future<void> saveGpxDotWaypointsJson(String? json) async {
  final prefs = await SharedPreferences.getInstance();
  if (json == null || json.isEmpty) {
    await prefs.remove(_keyGpxDotWaypoints);
    return;
  }
  await prefs.setString(_keyGpxDotWaypoints, json);
}

/// 保存済み Dot ウェイポイント JSON。未保存なら null
Future<String?> loadGpxDotWaypointsJson() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keyGpxDotWaypoints);
}

/// インポート時の GPX ファイル名ベースを保存する（エクスポート既定名・標高ダイアログ表示など）
Future<void> saveGpxImportBasename(String basenameWithoutExt) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyGpxImportBasename, basenameWithoutExt);
}

/// 保存済みのインポート GPX ファイル名ベース（拡張子除く）。未保存なら null
Future<String?> loadGpxImportBasename() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keyGpxImportBasename);
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

/// 位置ストリームの永続フラグ。現在はユーザーが明示的に OFF にしたときのみ false を保存する
Future<void> saveLocationStreamActive(bool active) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyLocationStreamActive, active);
}

/// 未使用（互換のため残置）。ストリーム ON 状態はプロセス内セッションのみで管理する。
Future<bool> loadLocationStreamActive() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyLocationStreamActive) ?? false;
}

/// 画面スリープ設定を保存する。true=ON（端末スリープに従う）、false=OFF（WakeLockでスリープしない）
Future<void> saveScreenSleep(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyScreenSleep, value);
}

/// 保存済みの画面スリープ設定を返す。未保存なら true（ON）
Future<bool> loadScreenSleep() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyScreenSleep) ?? true;
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

const _keyOfflineMapInfoDismissed = 'offline_map_info_dismissed';

/// オフラインマップ説明ダイアログを「以後表示しない」にしたかどうかを保存
Future<void> saveOfflineMapInfoDismissed(bool dismissed) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyOfflineMapInfoDismissed, dismissed);
}

/// オフラインマップ説明ダイアログを「以後表示しない」にしたかどうかを返す
Future<bool> loadOfflineMapInfoDismissed() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyOfflineMapInfoDismissed) ?? false;
}

/// 画面スリープ説明ダイアログを「以後表示しない」にしたかどうかを保存
Future<void> saveSleepInfoDismissed(bool dismissed) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keySleepInfoDismissed, dismissed);
}

/// 画面スリープ説明ダイアログを「以後表示しない」にしたかどうかを返す
Future<bool> loadSleepInfoDismissed() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keySleepInfoDismissed) ?? false;
}

/// 言語設定を保存する。'' はシステム設定に従う
Future<void> saveLocale(String languageCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyLocale, languageCode);
}

/// 保存済みの言語設定を返す。未保存なら null、'' はシステム設定に従う
Future<String?> loadLocale() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keyLocale);
}

/// バッテリー残量表示設定を保存する。true=表示、false=非表示
Future<void> saveBatteryDisplay(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyBatteryDisplay, value);
}

/// 保存済みのバッテリー残量表示設定を返す。未保存なら false（非表示）
Future<bool> loadBatteryDisplay() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyBatteryDisplay) ?? false;
}

/// リリースノートダイアログを最後に表示した `version+build`（未表示なら null）
Future<String?> loadLastShownReleaseNoteId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keyLastShownReleaseNoteId);
}

/// リリースノートを表示済みにする（[id] は [PackageInfo] の `version+build`）
Future<void> saveLastShownReleaseNoteId(String id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyLastShownReleaseNoteId, id);
}

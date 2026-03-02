import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/user_poi.dart';

const _keyUserPois = 'user_pois';

/// ユーザー追加 POI リストを SharedPreferences に保存する
Future<void> saveUserPois(List<UserPoi> pois) async {
  final prefs = await SharedPreferences.getInstance();
  final json = jsonEncode(pois.map((p) => p.toJson()).toList());
  await prefs.setString(_keyUserPois, json);
}

/// SharedPreferences からユーザー追加 POI リストを読み込む。未保存なら空リスト。
Future<List<UserPoi>> loadUserPois() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_keyUserPois);
  if (raw == null) return [];
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => UserPoi.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

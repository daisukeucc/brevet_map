import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../parsers/gpx_parser.dart';

/// ルートのメタ情報
class RouteEntry {
  const RouteEntry({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.hasTiles,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final bool hasTiles;

  factory RouteEntry.fromJson(Map<String, dynamic> json) => RouteEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        hasTiles: json['hasTiles'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'hasTiles': hasTiles,
      };

  RouteEntry copyWith({bool? hasTiles}) => RouteEntry(
        id: id,
        name: name,
        createdAt: createdAt,
        hasTiles: hasTiles ?? this.hasTiles,
      );
}

/// タイムスタンプベースのルートIDを生成する（例: "20240301_120000"）
String generateRouteId() {
  final n = DateTime.now();
  return '${n.year}${_p2(n.month)}${_p2(n.day)}_${_p2(n.hour)}${_p2(n.minute)}${_p2(n.second)}';
}

String _p2(int v) => v.toString().padLeft(2, '0');

Future<Directory> _routesBaseDir() async {
  final base = await getApplicationDocumentsDirectory();
  final d = Directory('${base.path}/routes');
  if (!d.existsSync()) await d.create(recursive: true);
  return d;
}

/// ルートディレクトリのパスを返す（存在しなければ作成）
Future<String> routeDirPath(String routeId) async {
  final base = await _routesBaseDir();
  final d = Directory('${base.path}/$routeId');
  if (!d.existsSync()) await d.create(recursive: true);
  return d.path;
}

/// タイルディレクトリのパスを返す（ディレクトリは作成しない）
Future<String> routeTilesDirPath(String routeId) async {
  final base = await _routesBaseDir();
  return '${base.path}/$routeId/tiles';
}

/// 指定ルートにタイルが存在するか確認する
Future<bool> routeHasTiles(String routeId) async {
  final tilesPath = await routeTilesDirPath(routeId);
  final dir = Directory(tilesPath);
  return dir.existsSync() && dir.listSync().isNotEmpty;
}

/// ルートデータ（ポリライン + POI）をファイルに保存する
Future<void> saveRouteToFile({
  required String routeId,
  required String name,
  required String encodedPolyline,
  required List<GpxPoi> pois,
}) async {
  final dir = await routeDirPath(routeId);
  final meta = RouteEntry(
    id: routeId,
    name: name,
    createdAt: DateTime.now(),
    hasTiles: await routeHasTiles(routeId),
  );
  await File('$dir/meta.json').writeAsString(jsonEncode(meta.toJson()));
  await File('$dir/route.json').writeAsString(jsonEncode({
    'polyline': encodedPolyline,
    'pois': pois.map((p) => p.toJson()).toList(),
  }));
}

/// ルートデータをファイルから読み込む
Future<({String? polyline, List<GpxPoi> pois})?> loadRouteFromFile(
    String routeId) async {
  final base = await _routesBaseDir();
  final file = File('${base.path}/$routeId/route.json');
  if (!file.existsSync()) return null;
  try {
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final polyline = json['polyline'] as String?;
    final pois = ((json['pois'] as List<dynamic>?) ?? [])
        .map((e) => GpxPoi.fromJson(e as Map<String, dynamic>))
        .toList();
    return (polyline: polyline, pois: pois);
  } catch (_) {
    return null;
  }
}

/// meta.json の hasTiles フラグを現在のタイル存在状態で更新する
Future<void> updateRouteHasTiles(String routeId) async {
  final base = await _routesBaseDir();
  final metaFile = File('${base.path}/$routeId/meta.json');
  if (!metaFile.existsSync()) return;
  try {
    final json =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    final updated =
        RouteEntry.fromJson(json).copyWith(hasTiles: await routeHasTiles(routeId));
    await metaFile.writeAsString(jsonEncode(updated.toJson()));
  } catch (_) {}
}

/// 全ルートのエントリ一覧を返す（新しい順）
Future<List<RouteEntry>> listRoutes() async {
  final dir = await _routesBaseDir();
  final entries = <RouteEntry>[];
  for (final entity in dir.listSync()) {
    if (entity is! Directory) continue;
    final metaFile = File('${entity.path}/meta.json');
    if (!metaFile.existsSync()) continue;
    try {
      final json =
          jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
      entries.add(RouteEntry.fromJson(json));
    } catch (_) {}
  }
  entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return entries;
}

/// ルートをタイルごと削除する
Future<void> deleteRoute(String routeId) async {
  final base = await _routesBaseDir();
  final dir = Directory('${base.path}/$routeId');
  if (dir.existsSync()) await dir.delete(recursive: true);
}

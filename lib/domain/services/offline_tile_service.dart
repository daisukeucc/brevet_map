import 'dart:io';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

const int _minZoom = 8;
const int _maxZoom = 15;
const String _storeDirName = 'offline_tiles';

/// オフラインタイルの保存ディレクトリを返す
Future<Directory> getOfflineTileDir() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/$_storeDirName');
  if (!dir.existsSync()) await dir.create(recursive: true);
  return dir;
}

int _lngToX(double lng, int zoom) =>
    ((lng + 180) / 360 * (1 << zoom)).floor();

int _latToY(double lat, int zoom) {
  final rad = lat * pi / 180;
  return ((1 - log(tan(rad) + 1 / cos(rad)) / pi) / 2 * (1 << zoom)).floor();
}

List<(int z, int x, int y)> _tilesForZoom(LatLngBounds bounds, int zoom) {
  final x0 = _lngToX(bounds.west, zoom);
  final x1 = _lngToX(bounds.east, zoom);
  final y0 = _latToY(bounds.north, zoom);
  final y1 = _latToY(bounds.south, zoom);
  return [
    for (var x = x0; x <= x1; x++)
      for (var y = y0; y <= y1; y++) (zoom, x, y),
  ];
}

/// ダウンロードするタイルの総数を返す
int countTiles(LatLngBounds bounds) {
  var count = 0;
  for (var z = _minZoom; z <= _maxZoom; z++) {
    count += _tilesForZoom(bounds, z).length;
  }
  return count;
}

/// bounds のタイルをダウンロードして保存する。進捗 0.0〜1.0 を Stream で返す。
Stream<double> downloadTiles(LatLngBounds bounds, String urlTemplate) async* {
  final dir = await getOfflineTileDir();
  final total = countTiles(bounds);
  if (total == 0) return;
  var done = 0;

  for (var z = _minZoom; z <= _maxZoom; z++) {
    for (final (tz, tx, ty) in _tilesForZoom(bounds, z)) {
      final filePath = '${dir.path}/${tz}_${tx}_$ty.png';
      if (!File(filePath).existsSync()) {
        // CartoDB @2x タグを除いて標準解像度タイルを取得
        final url = urlTemplate
            .replaceAll('{z}', '$tz')
            .replaceAll('{x}', '$tx')
            .replaceAll('{y}', '$ty')
            .replaceAll('@2x', '');
        try {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200) {
            await File(filePath).writeAsBytes(res.bodyBytes);
          }
        } catch (_) {}
      }
      done++;
      yield done / total;
    }
  }
}

/// 保存済みオフラインタイルが存在するか確認する
Future<bool> hasOfflineTiles() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory('${base.path}/$_storeDirName');
  return dir.existsSync() && dir.listSync().isNotEmpty;
}

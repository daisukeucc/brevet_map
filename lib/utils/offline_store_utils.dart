import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

/// オフライン地図ストアの保存容量を人間が読める形式で返す。
/// ストアが存在しない場合は "0 B" を返す。
///
/// FMTC の [StoreStats.size] は KiB 単位のため、バイトに変換してからフォーマットする。
Future<String> getOfflineStoreSizeFormatted(String storeName) async {
  final store = FMTCStore(storeName);
  final exists = await store.manage.ready;
  if (!exists) return '0 B';

  final stats = await store.stats.all;
  final bytes = stats.size * 1024; // KiB → bytes
  return _formatBytes(bytes);
}

String _formatBytes(double bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

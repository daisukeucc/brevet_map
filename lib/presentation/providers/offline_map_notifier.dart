import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/services/offline_tile_service.dart';

enum OfflineDownloadStatus { success, error }

@immutable
class OfflineMapState {
  const OfflineMapState({
    this.isAvailable = false,
    this.isUsing = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.offlineDirPath,
  });

  final bool isAvailable;
  final bool isUsing;
  final bool isDownloading;
  final double downloadProgress;

  /// OfflineTileProvider に渡すローカルディレクトリパス
  final String? offlineDirPath;

  OfflineMapState copyWith({
    bool? isAvailable,
    bool? isUsing,
    bool? isDownloading,
    double? downloadProgress,
    String? offlineDirPath,
  }) =>
      OfflineMapState(
        isAvailable: isAvailable ?? this.isAvailable,
        isUsing: isUsing ?? this.isUsing,
        isDownloading: isDownloading ?? this.isDownloading,
        downloadProgress: downloadProgress ?? this.downloadProgress,
        offlineDirPath: offlineDirPath ?? this.offlineDirPath,
      );
}

class OfflineMapNotifier extends Notifier<OfflineMapState> {
  @override
  OfflineMapState build() {
    _checkExisting();
    return const OfflineMapState();
  }

  /// 起動時に保存済みタイルの有無を確認して state を更新する
  Future<void> _checkExisting() async {
    if (!await hasOfflineTiles()) return;
    final base = await getApplicationDocumentsDirectory();
    state = state.copyWith(
      isAvailable: true,
      offlineDirPath: '${base.path}/offline_tiles',
    );
  }

  /// ルート範囲のタイルをダウンロードする
  Future<OfflineDownloadStatus> download(
      LatLngBounds bounds, String urlTemplate) async {
    state = state.copyWith(isDownloading: true, downloadProgress: 0.0);
    try {
      await for (final progress in downloadTiles(bounds, urlTemplate)) {
        state = state.copyWith(downloadProgress: progress);
      }
      final base = await getApplicationDocumentsDirectory();
      state = state.copyWith(
        isDownloading: false,
        isAvailable: true,
        downloadProgress: 1.0,
        offlineDirPath: '${base.path}/offline_tiles',
      );
      return OfflineDownloadStatus.success;
    } catch (_) {
      state = state.copyWith(isDownloading: false);
      return OfflineDownloadStatus.error;
    }
  }

  /// オフラインマップに切り替える
  void useOfflineMap() => state = state.copyWith(isUsing: true);

  /// オンラインマップに戻す
  void useOnlineMap() => state = state.copyWith(isUsing: false);
}

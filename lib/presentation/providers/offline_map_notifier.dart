import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/route_repository.dart';
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
  OfflineMapState build() => const OfflineMapState();

  /// 指定ルートのタイル有無を確認して state を更新する。
  /// ルートがロードされた後（home_screen から）呼び出す。
  Future<void> checkTilesForRoute(String routeId) async {
    if (!await routeHasTiles(routeId)) {
      // タイルが存在しない場合は isAvailable を false に戻す
      if (state.isAvailable) {
        state = state.copyWith(
          isAvailable: false,
          offlineDirPath: null,
        );
      }
      return;
    }
    final tilesPath = await routeTilesDirPath(routeId);
    state = state.copyWith(
      isAvailable: true,
      offlineDirPath: tilesPath,
    );
  }

  /// ルート範囲のタイルを routeId フォルダにダウンロードする
  Future<OfflineDownloadStatus> download(
    LatLngBounds bounds,
    String urlTemplate,
    String routeId,
  ) async {
    state = state.copyWith(isDownloading: true, downloadProgress: 0.0);
    try {
      await for (final progress in downloadTiles(bounds, urlTemplate, routeId)) {
        state = state.copyWith(downloadProgress: progress);
      }
      await updateRouteHasTiles(routeId);
      final tilesPath = await routeTilesDirPath(routeId);
      state = state.copyWith(
        isDownloading: false,
        isAvailable: true,
        downloadProgress: 1.0,
        offlineDirPath: tilesPath,
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

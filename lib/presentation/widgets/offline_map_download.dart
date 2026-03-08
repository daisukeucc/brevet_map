import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/tile_config.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/map_utils.dart';
import '../providers/providers.dart';
import '../theme/app_text_styles.dart';
import '../utils/snackbar_utils.dart';
import 'confirm_dialog.dart';
import 'text_menu_dialog.dart';

/// オフラインマップのダウンロードフローを実行する。
/// ルートが読み込まれていない場合は SnackBar で通知し、何もしない。
Future<void> showOfflineMapDownloadFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;

  final routePoints = ref.read(mapStateProvider).fullRoutePoints ??
      ref.read(mapStateProvider).savedRoutePoints;
  if (routePoints == null || routePoints.isEmpty) {
    if (!context.mounted) return;
    showAppSnackBar(context, l10n.offlineMapNoRoute);
    return;
  }

  final bounds = boundsFromPoints(routePoints);
  if (bounds == null || !context.mounted) return;

  // 10% のパディングを追加
  final latPad = (bounds.north - bounds.south) * 0.1 / 2;
  final lngPad = (bounds.east - bounds.west) * 0.1 / 2;
  final paddedBounds = LatLngBounds.unsafe(
    north: (bounds.north + latPad).clamp(-85.0, 85.0),
    south: (bounds.south - latPad).clamp(-85.0, 85.0),
    east: (bounds.east + lngPad).clamp(-180.0, 180.0),
    west: (bounds.west - lngPad).clamp(-180.0, 180.0),
  );

  final tileLayerOptions = TileLayer(
    urlTemplate: TileConfig.tileUrlTemplate,
    userAgentPackageName: TileConfig.userAgentPackageName,
  );

  // 3オプションのタイル数を並列で取得し、推定サイズを算出
  const bytesPerTile = 18 * 1024;
  String sizeStr(int tileCount) {
    final estimatedMB = (tileCount * bytesPerTile) / (1024 * 1024);
    return estimatedMB >= 1024
        ? '${(estimatedMB / 1024).toStringAsFixed(1)} GB'
        : '${estimatedMB.toStringAsFixed(1)} MB';
  }

  List<String> menuItems;
  List<String>? sizeStrings;
  try {
    final regions = [
      RectangleRegion(paddedBounds).toDownloadable(
        minZoom: 14,
        maxZoom: 14,
        options: tileLayerOptions,
      ),
      RectangleRegion(paddedBounds).toDownloadable(
        minZoom: 14,
        maxZoom: 16,
        options: tileLayerOptions,
      ),
      RectangleRegion(paddedBounds).toDownloadable(
        minZoom: 14,
        maxZoom: 18,
        options: tileLayerOptions,
      ),
    ];
    final counts = await Future.wait(
      regions.map((r) => FMTCStore('mapStore').download.countTiles(r)),
    );
    sizeStrings = [
      sizeStr(counts[0]),
      sizeStr(counts[1]),
      sizeStr(counts[2]),
    ];
    menuItems = [
      l10n.offlineMapZoomSmallWithSize(sizeStrings[0]),
      l10n.offlineMapZoomMediumWithSize(sizeStrings[1]),
      l10n.offlineMapZoomLargeWithSize(sizeStrings[2]),
    ];
  } catch (_) {
    menuItems = [
      l10n.offlineMapZoomSmall,
      l10n.offlineMapZoomMedium,
      l10n.offlineMapZoomLarge,
    ];
  }

  if (!context.mounted) return;
  final selected = await showTextMenuDialog(context, items: menuItems);
  if (selected == null || !context.mounted) return;

  // 0=z14のみ, 1=z14-16, 2=z14-18
  final maxZoom = switch (selected) {
    0 => 14,
    1 => 16,
    _ => 18,
  };

  final region = RectangleRegion(paddedBounds).toDownloadable(
    minZoom: 14,
    maxZoom: maxZoom,
    options: tileLayerOptions,
  );

  // ズームレベル中・大の場合はWi-Fi推奨の確認ダイアログを表示（推定サイズ付き）
  if (selected == 1 || selected == 2) {
    if (!context.mounted) return;
    final message = sizeStrings != null && selected < sizeStrings.length
        ? l10n.offlineMapWifiRecommendationWithSize(sizeStrings[selected])
        : l10n.offlineMapWifiRecommendation;
    if (!context.mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      message: message,
      cancelText: l10n.cancel,
      confirmText: l10n.ok,
    );
    if (confirmed != true || !context.mounted) return;
  }

  if (!context.mounted) return;
  // コールバックで context/ref を使わないため、事前にキャプチャ
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => OfflineMapDownloadDialog(
      storeName: 'mapStore',
      region: region,
      onComplete: () {
        if (ctx.mounted) Navigator.of(ctx).pop();
        showAppSnackBarWithMessenger(
            messenger, l10n.offlineMapDownloadComplete);
      },
      onFailed: () {
        if (ctx.mounted) Navigator.of(ctx).pop();
        showAppSnackBarWithMessenger(
            messenger, l10n.offlineMapDownloadFailed);
      },
      onCancelled: () {
        if (ctx.mounted) Navigator.of(ctx).pop();
        showAppSnackBarWithMessenger(
            messenger, l10n.offlineMapDownloadCancelled);
      },
    ),
  );
}

/// オフラインマップダウンロード進捗ダイアログ
class OfflineMapDownloadDialog extends StatefulWidget {
  const OfflineMapDownloadDialog({
    super.key,
    required this.storeName,
    required this.region,
    required this.onComplete,
    required this.onFailed,
    required this.onCancelled,
  });

  final String storeName;
  final DownloadableRegion<RectangleRegion> region;
  final VoidCallback onComplete;
  final VoidCallback onFailed;
  final VoidCallback onCancelled;

  @override
  State<OfflineMapDownloadDialog> createState() =>
      _OfflineMapDownloadDialogState();
}

class _OfflineMapDownloadDialogState extends State<OfflineMapDownloadDialog> {
  double _progress = 0;
  StreamSubscription<DownloadProgress>? _subscription;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _onCancelTap() async {
    if (_cancelled) return;
    setState(() => _cancelled = true);
    await FMTCStore(widget.storeName).download.cancel();
    if (mounted) widget.onCancelled();
  }

  Future<void> _startDownload() async {
    try {
      final result = FMTCStore(widget.storeName).download.startForeground(
        region: widget.region,
        skipExistingTiles: true,
      );
      _subscription = result.downloadProgress.listen(
        (p) {
          if (mounted && !_cancelled) {
            final pct = p.percentageProgress;
            if (pct.isFinite && !pct.isNaN) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_cancelled) {
                  setState(() => _progress = pct.clamp(0.0, 100.0) / 100);
                }
              });
            }
          }
        },
        onDone: () async {
          if (_cancelled) return;
          if (mounted) {
            setState(() => _progress = 1.0);
            await Future.delayed(const Duration(milliseconds: 500));
          }
          if (mounted) widget.onComplete();
        },
        onError: (_) {
          if (_cancelled) return;
          if (mounted) widget.onFailed();
        },
      );
    } catch (e) {
      if (_cancelled) return;
      if (mounted) widget.onFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final percent = (_progress * 100).clamp(0.0, 100.0).round();
    final compactButtonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return AlertDialog(
      shape: const RoundedRectangleBorder(),
      contentPadding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l10n.offlineMapDownloading}$percent%',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                style: compactButtonStyle,
                onPressed: _cancelled ? null : _onCancelTap,
                child: Text(l10n.offlineMapCancel, style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

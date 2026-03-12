import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/tile_config.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/connectivity_check.dart';
import '../../utils/map_utils.dart';
import '../../utils/offline_store_utils.dart';
import '../providers/providers.dart';
import '../theme/app_text_styles.dart';
import '../utils/snackbar_utils.dart';
import 'confirm_dialog.dart';
import 'text_menu_dialog.dart';

/// 番号付きリスト行かどうか（1. 2-1. 2-2. 3. など）
bool _isListLine(String line) {
  final t = line.trimLeft();
  return RegExp(r'^\d+(?:-\d+)?\.\s').hasMatch(t);
}

/// 説明文をマークダウン風に表示（見出し・番号付きリストのインデント揃え）。
/// リストでは継続行を番号なしでインデントして表示する。
Widget _buildCacheClearConfirmContent(String message, TextStyle bodyStyle) {
  final paragraphs = message.split(RegExp(r'\n\n+'));
  const listMarkerWidth = 32.0; // 2-2. の幅でリスト本文を揃え、番号後の余白を抑える

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final p in paragraphs) ...[
        if (p != paragraphs.first) const SizedBox(height: 16),
        Builder(
          builder: (context) {
            final lines = p.split('\n');
            final hasListLine = lines.any((l) => _isListLine(l.trimLeft()));
            if (hasListLine && lines.isNotEmpty) {
              // リスト段落: 番号行と継続行をまとめて表示
              final items = <(String marker, List<String> contentLines)>[];
              for (final line in lines) {
                final t = line.trimLeft();
                final m = RegExp(r'^(\d+(?:-\d+)?\.\s+)(.*)$').firstMatch(t);
                if (m != null) {
                  items.add((m.group(1)!, [m.group(2)!]));
                } else if (items.isNotEmpty && t.isNotEmpty) {
                  items.last.$2.add(t);
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: listMarkerWidth,
                            child: Text(
                              item.$1,
                              style: bodyStyle,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final contentLine in item.$2)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      contentLine,
                                      style: bodyStyle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }
            // 単一行なら見出し風に
            if (lines.length == 1 && lines.single.length < 24) {
              return Text(
                lines.single,
                style: AppTextStyles.body,
              );
            }
            return Text(p, style: bodyStyle);
          },
        ),
      ],
    ],
  );
}

/// キャッシュクリア確認ダイアログ（スクロール可能な説明文付き）。
/// キャンセルで false、キャッシュクリアで true を返す。
Future<bool?> _showCacheClearConfirmDialog(
  BuildContext context,
  AppLocalizations l10n,
) {
  final compactButtonStyle = ButtonStyle(
    minimumSize: WidgetStateProperty.all(Size.zero),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: const RoundedRectangleBorder(),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCacheClearConfirmContent(
              l10n.offlineMapCacheClearConfirmMessage,
              AppTextStyles.body.copyWith(fontSize: 15, height: 1.6),
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          style: compactButtonStyle,
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel, style: AppTextStyles.button),
        ),
        TextButton(
          style: compactButtonStyle,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.offlineMapCacheClearConfirmButton,
              style: AppTextStyles.button),
        ),
      ],
    ),
  );
}

/// オフラインマップのダウンロードフローを実行する。
/// ルートが読み込まれていない場合やオフラインの場合は SnackBar で通知し、何もしない。
Future<void> showOfflineMapDownloadFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;

  // ダウンロードはネットワーク必須のため、オフライン時は開始しない
  if (!await checkConnectivity()) {
    if (!context.mounted) return;
    showAppSnackBar(context, l10n.offlineMapRequiresNetwork);
    return;
  }

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

  final languageCode = Localizations.localeOf(context).languageCode;
  final urlTemplate = TileConfig.getTileUrlTemplate(languageCode);
  final useOsmOrg = urlTemplate.contains('tile.openstreetmap.org');
  final tileLayerOptions = TileLayer(
    urlTemplate: urlTemplate,
    userAgentPackageName: TileConfig.userAgentPackageName,
    subdomains: useOsmOrg ? const [] : const ['a', 'b', 'c'],
    tileProvider: NetworkTileProvider(
      headers: {'User-Agent': TileConfig.userAgent},
    ),
  );

  // 3オプションのタイル数を並列で取得し、推定サイズを算出
  const bytesPerTile = 18 * 1024;
  String sizeStr(int tileCount) {
    final estimatedMB = (tileCount * bytesPerTile) / (1024 * 1024);
    return estimatedMB >= 1024
        ? '${(estimatedMB / 1024).toStringAsFixed(1)} GB'
        : '${estimatedMB.toStringAsFixed(1)} MB';
  }

  // 保存済み容量はメニュー4項目目（キャッシュクリア）で表示するため先に取得
  final storedSize = await getOfflineStoreSizeFormatted('mapStore');
  if (!context.mounted) return;

  List<String> menuItems;
  List<String>? sizeStrings;
  List<double>? estimatedMBList;
  try {
    final regions = [
      RectangleRegion(paddedBounds).toDownloadable(
        minZoom: 10,
        maxZoom: 14,
        options: tileLayerOptions,
      ),
      RectangleRegion(paddedBounds).toDownloadable(
        minZoom: 10,
        maxZoom: 16,
        options: tileLayerOptions,
      ),
    ];
    final counts = await Future.wait(
      regions.map((r) => FMTCStore('mapStore').download.countTiles(r)),
    );
    estimatedMBList = [
      (counts[0] * bytesPerTile) / (1024 * 1024),
      (counts[1] * bytesPerTile) / (1024 * 1024),
    ];
    sizeStrings = [
      sizeStr(counts[0]),
      sizeStr(counts[1]),
    ];
    menuItems = [
      l10n.offlineMapMinimalMapWithSize(sizeStrings[0]),
      l10n.offlineMapStandardMapWithSize(sizeStrings[1]),
      l10n.offlineMapCacheClearWithSize(storedSize),
    ];
  } catch (_) {
    menuItems = [
      l10n.offlineMapMinimalMap,
      l10n.offlineMapStandardMap,
      l10n.offlineMapCacheClearWithSize(storedSize),
    ];
  }

  if (!context.mounted) return;
  final selected = await showTextMenuDialog(context, items: menuItems);
  if (selected == null || !context.mounted) return;

  // 2=キャッシュクリア
  if (selected == 2) {
    final confirmed = await _showCacheClearConfirmDialog(context, l10n);
    if (!context.mounted || confirmed != true) return;
    const storeName = 'mapStore';
    final exists = await FMTCStore(storeName).manage.ready;
    if (exists) {
      await FMTCStore(storeName).manage.reset();
    }
    if (!context.mounted) return;
    showAppSnackBar(context, l10n.offlineMapCacheCleared);
    return;
  }

  // 0=最小地図(z10-14), 1=標準地図(z10-16)
  final maxZoom = switch (selected) {
    0 => 14,
    _ => 16,
  };

  final region = RectangleRegion(paddedBounds).toDownloadable(
    minZoom: 10,
    maxZoom: maxZoom,
    options: tileLayerOptions,
  );

  // 推定サイズが50 MB以上の場合はWi-Fi推奨の確認ダイアログを表示（推定サイズ付き）
  const wifiRecommendationThresholdMB = 50.0;
  final estimatedMB = estimatedMBList != null && selected < estimatedMBList.length
      ? estimatedMBList[selected]
      : null;
  if (estimatedMB != null && estimatedMB >= wifiRecommendationThresholdMB) {
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
        showAppSnackBarWithMessenger(messenger, l10n.offlineMapDownloadFailed);
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
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
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

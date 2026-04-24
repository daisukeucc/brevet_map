import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../domain/models/bm_extension.dart';
import '../../domain/models/user_poi.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/offline_map_download.dart';
import '../widgets/radio_selection_dialog.dart';
import 'distance_unit_handler.dart';
import 'gpx_export_handler.dart';
import 'gpx_import_handler.dart';
import 'poi_management_handler.dart';
import 'offline_map_info_dialog.dart';
import 'sleep_info_dialog.dart';
import 'sleep_settings_handler.dart';

/// ボトムシートを閉じ、アニメーション完了後にコールバックを実行する
/// メニュータップ後のシート閉じ〜処理開始の共通パターン
/// 150ms: タップフィードバック（グレー表示）を見せてから pop
/// pop の Future 完了（アニメーション終了）を await してからコールバックを実行することで
/// Navigator アニメーション競合によるダイアログ未表示を防ぐ
void popSheetAndCall(BuildContext context, VoidCallback callback) {
  final navigator = Navigator.of(context);
  Future.delayed(const Duration(milliseconds: 150), () async {
    await navigator.maybePop();
    callback();
  });
}

/// GPXインポートメニューがタップされたときのフロー
Future<void> handleGpxImportTap(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onSuccess,
}) async {
  await showGpxImportFlow(context, ref, onSuccess: onSuccess);
}

/// GPXエクスポートメニューがタップされたときのフロー
Future<void> handleGpxExportTap(BuildContext context, WidgetRef ref) async {
  await showGpxExportFlow(context, ref);
}

/// オフラインマップメニューがタップされたときのフロー
Future<void> handleOfflineMapTap(BuildContext context, WidgetRef ref) async {
  if (!context.mounted) return;

  final dismissed = await loadOfflineMapInfoDismissed();
  if (!context.mounted) return;

  if (!dismissed) {
    final proceed = await showOfflineMapInfoDialog(context);
    if (!context.mounted) return;
    if (!proceed) return;
  }

  try {
    await showOfflineMapDownloadFlow(context, ref);
  } catch (_) {
    // showOfflineMapDownloadFlow 内の予期しない例外をサイレントに握り潰す
    // （ネイティブ例外等によるクラッシュ防止）
  }
}

/// POI追加・編集メニューがタップされたときのフロー
Future<void> handleAddPoiTap(
  BuildContext context,
  WidgetRef ref, {
  required bool Function() getMounted,
  required VoidCallback onStartMapTapAddMode,
  required VoidCallback onStartDragMode,
  required void Function(UserPoi poi, LatLng newLatLng) onDragEnd,
}) async {
  if (!getMounted()) return;

  final meta = await loadBrevetMeta();
  if (meta?.startTime == null) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: l10n.setStartDate,
    );
    if (selectedDate == null || !getMounted() || !context.mounted) return;
    final startTime =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 6)
            .toUtc();
    await saveBrevetMeta(BmBrevetMeta(
      distanceKm: meta?.distanceKm ?? 0,
      startTime: startTime,
      timeLimitHours: meta?.timeLimitHours ?? 0,
    ));
  }

  if (!getMounted() || !context.mounted) return;
  final result = await showPoiManagementDialog(context, ref);
  if (result == null || !getMounted()) return;

  if (result is MapTapAddRequest) {
    onStartMapTapAddMode();
    return;
  }
  if (result is PoiEditPositionRequest) {
    if (!context.mounted) return;
    await handleStartEditPoiPosition(
      context,
      ref,
      result.poi,
      onStartDragMode: onStartDragMode,
      onDragEnd: onDragEnd,
    );
    return;
  }
}

/// スリープ設定メニューがタップされたときのフロー
Future<void> showSleepSettingsFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!context.mounted) return;

  final dismissed = await loadSleepInfoDismissed();
  if (!context.mounted) return;

  if (!dismissed) {
    final proceed = await showSleepInfoDialog(context);
    if (!context.mounted) return;
    if (!proceed) return;
  }

  showSleepSettingsDialog(context, ref);
}

/// 距離単位メニューがタップされたときのフロー
Future<void> showDistanceUnitFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  showRadioSelectionDialog<int>(
    context: context,
    title: l10n.distanceUnit,
    options: [
      (0, l10n.unitKm),
      (1, l10n.unitMile),
    ],
    initialValue: ref.read(distanceUnitProvider),
    onChanged: (unit) => handleDistanceUnitChange(context, ref, unit),
  );
}

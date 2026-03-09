import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/models/user_poi.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../widgets/offline_map_download.dart';
import '../widgets/radio_selection_dialog.dart';
import 'distance_unit_handler.dart';
import 'gpx_export_handler.dart';
import 'gpx_import_handler.dart';
import 'poi_management_handler.dart';
import 'sleep_settings_handler.dart';

/// ボトムシートを閉じ、遅延後にコールバックを実行する
/// メニュータップ後のシート閉じ〜処理開始の共通パターン
void popSheetAndCall(BuildContext context, VoidCallback callback) {
  final navigator = Navigator.of(context);
  Future.delayed(const Duration(milliseconds: 200), () {
    navigator.pop();
    callback();
  });
}

/// GPXインポートメニューがタップされたときのフロー
Future<void> handleGpxImportTap(BuildContext context, WidgetRef ref) async {
  await showGpxImportFlow(context, ref);
}

/// GPXエクスポートメニューがタップされたときのフロー
Future<void> handleGpxExportTap(BuildContext context, WidgetRef ref) async {
  await showGpxExportFlow(context, ref);
}

/// オフラインマップメニューがタップされたときのフロー
Future<void> handleOfflineMapTap(BuildContext context, WidgetRef ref) async {
  await showOfflineMapDownloadFlow(context, ref);
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
  final result = await showPoiManagementDialog(context, ref);
  if (result == null || !getMounted()) return;

  if (result is MapTapAddRequest) {
    onStartMapTapAddMode();
    return;
  }
  if (result is DistanceInputRequest) {
    await handleDistanceInputPoiAdd(context, ref);
    return;
  }
  if (result is PoiEditTextRequest) {
    await handleEditPoiText(context, ref, result.poi);
    return;
  }
  if (result is PoiEditPositionRequest) {
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
  WidgetRef ref, {
  required VoidCallback restoreBrightness,
  required void Function(int) restartTimer,
}) async {
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  showRadioSelectionDialog<int>(
    context: context,
    title: l10n.sleepSettings,
    options: [
      (0, l10n.sleepOff),
      (1, l10n.sleep1min),
      (5, l10n.sleep5min),
      (10, l10n.sleep10min),
    ],
    initialValue: ref.read(sleepDurationProvider),
    onChanged: (minutes) => handleSleepDurationChange(
      context,
      ref,
      minutes,
      restoreBrightness: restoreBrightness,
      restartTimer: restartTimer,
    ),
  );
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

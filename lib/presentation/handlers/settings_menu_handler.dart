import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../data/repositories/first_launch_repository.dart';
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
import 'trial_info_dialog.dart';

/// ボトムシートを閉じ、アニメーション完了後にコールバックを実行する
/// メニュータップ後のシート閉じ〜処理開始の共通パターン
/// 150ms: タップフィードバック（グレー表示）を見せてから pop
/// さらに 350ms: 閉じアニメーション完了を待ってからコールバック実行
/// ※pop と callback を同時に呼ぶとナビゲーターアニメーション競合でダイアログが表示されない
void popSheetAndCall(BuildContext context, VoidCallback callback) {
  final navigator = Navigator.of(context);
  Future.delayed(const Duration(milliseconds: 150), () {
    navigator.pop();
    Future.delayed(const Duration(milliseconds: 500), callback);
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

/// トライアル期間中はダイアログを表示し、期間終了後はペイウォールを表示する共通処理。
/// 「定期購入」タップ時は true を返す（呼び出し側で次のダイアログをスキップする）。
Future<bool> _showTrialOrPaywall(BuildContext context) async {
  const trialPeriod = 30;
  try {
    final customerInfo = await Purchases.getCustomerInfo();
    final firstSeen = DateTime.tryParse(customerInfo.firstSeen);
    assert(() {
      debugPrint('[Trial] firstSeen: $firstSeen');
      return true;
    }());
    if (firstSeen != null) {
      final elapsed = DateTime.now().difference(firstSeen).inDays;
      if (elapsed < trialPeriod) {
        if (!context.mounted) return false;
        return await showTrialInfoDialog(context,
            remainingDays: trialPeriod - elapsed);
      }
    }
  } catch (_) {}
  if (!context.mounted) return false;
  await RevenueCatUI.presentPaywallIfNeeded('premium');
  return true;
}

/// GPXエクスポートメニューがタップされたときのフロー
Future<void> handleGpxExportTap(BuildContext context, WidgetRef ref) async {
  if (!context.mounted) return;
  final subscribed = await _showTrialOrPaywall(context);
  if (!context.mounted || subscribed) return;
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
  final subscribed = await _showTrialOrPaywall(context);
  if (!getMounted() || subscribed) return;
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

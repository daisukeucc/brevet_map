import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/map_utils.dart';
import '../providers/providers.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/hp_setup_dialog.dart';

/// ルート上とみなす距離の閾値（メートル）
const double _onRouteThresholdM = 1000;

/// 吹き出し用のメインテキストを取得する。
/// 吹き出し表示や共有時に使用。routePoints, currentPosition, unit が揃っている場合に利用。
String getLocationCalloutMainText({
  required List<LatLng>? routePoints,
  required LatLng? currentPosition,
  LatLng? previousPosition,
  required int unit,
}) {
  if (routePoints == null || routePoints.isEmpty || currentPosition == null) {
    return 'Ready to Start!';
  }
  final result = getRouteLegWithBearing(
    routePoints,
    currentPosition,
    previousPosition: previousPosition,
  );
  if (result.toRouteM >= _onRouteThresholdM) {
    return 'Ready to Start!';
  }
  final distKm = result.alongTrackM / 1000;
  final totalM = distanceAlongTrackFromStart(
    routePoints,
    routePoints.length - 1,
  );
  if (result.alongTrackM < 500) {
    return 'Start!';
  }
  if (totalM > 0 && (totalM - result.alongTrackM) < 500) {
    return 'Goal!';
  }
  return '@${formatDistance(distKm, unit)}!';
}

/// 吹き出し表示用の位置とテキストを算出する。
/// isShareMode かつ 位置あり の場合のみ non-null を返す。
({LatLng? position, String? text}) computeCalloutData({
  required bool isShareMode,
  required bool hasPosition,
  required LatLng? currentPosition,
  LatLng? previousPosition,
  required List<LatLng>? routePoints,
  required int distanceUnit,
}) {
  if (!isShareMode || !hasPosition || currentPosition == null) {
    return (position: null, text: null);
  }
  return (
    position: currentPosition,
    text: getLocationCalloutMainText(
      routePoints: routePoints,
      currentPosition: currentPosition,
      previousPosition: previousPosition,
      unit: distanceUnit,
    ),
  );
}

/// 共有ボタンタップ時の処理。HP設定ダイアログ→吹き出し表示→共有フローを実行する。
Future<void> handleShareButtonTap({
  required BuildContext context,
  required WidgetRef ref,
  required GlobalKey screenshotKey,
  LatLng? currentPosition,
  LatLng? previousPosition,
  required void Function(bool isShareMode, {double? shareHp}) onShareModeChanged,
  required bool Function() getMounted,
}) async {
  final hp = await showHpSetupDialog(context);
  if (hp == null || !getMounted()) return;

  onShareModeChanged(true, shareHp: hp / 100);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showShareFlow(
      context,
      ref,
      screenshotKey,
      currentPosition: currentPosition,
      previousPosition: previousPosition,
    ).whenComplete(() {
      if (getMounted()) onShareModeChanged(false);
    });
  });
}

/// 地図スクリーンショットの共有フローを実行する。
/// ルートがある場合は拡大表示し、ルート上（1km以内）であれば距離を含むテキストを共有する。
Future<void> showShareFlow(
  BuildContext context,
  WidgetRef ref,
  GlobalKey screenshotKey, {
  LatLng? currentPosition,
  LatLng? previousPosition,
}) async {
  final boundary = screenshotKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null || !context.mounted) return;

  try {
    // 1. ルートを拡大表示
    final mapState = ref.read(mapStateProvider);
    final routePoints = mapState.fullRoutePoints ?? mapState.savedRoutePoints;
    final bounds = routePoints != null && routePoints.isNotEmpty
        ? boundsFromPoints(routePoints)
        : null;
    if (bounds != null) {
      await ref.read(cameraControllerProvider.notifier).animateToBounds(bounds);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!context.mounted) return;

    // 2. ボタン含む複雑なシーンの描画完了を待つ
    await Future.delayed(const Duration(milliseconds: 150));
    if (!context.mounted) return;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData == null || !context.mounted) return;

    final gpxName = await loadGpxMetadataName();
    final fileName = 'brevet_map_${DateTime.now().millisecondsSinceEpoch}.png';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    if (!context.mounted) return;
    await Share.shareXFiles(
      [XFile(file.path)],
      text: gpxName != null && gpxName.trim().isNotEmpty ? gpxName.trim() : null,
    );
  } catch (e) {
    if (context.mounted) {
      showAppSnackBar(context, AppLocalizations.of(context)!.shareFailed);
    }
  }
}
